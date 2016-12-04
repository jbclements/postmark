#lang typed/racket/base

;; some basic Postmark functionality.
;; NB: Uses only http-sendrecv, for simplicity.
;; keeping connections live would presumably
;; be more efficient for some applications.

(require typed/net/http-client
         typed/json
         typed/rackunit
         typed/net/uri-codec
         racket/match)

(provide send-single-email
         deliverystats
         postmark-post
         postmark-get
         send-to-endpoint/inner
         TESTING-SERVER-TOKEN)

(define SERVER-TOKEN-TAG #"X-Postmark-Server-Token")
(define ACCOUNT-TOKEN-TAG #"X-Postmark-Account-Token")

(define TESTING-SERVER-TOKEN #"POSTMARK_API_TEST")

(define POSTMARK-HOST "api.postmarkapp.com")

;; SEND A SINGLE EMAIL

;; send a single email
(: send-single-email (Bytes #:From String #:To String #:Body String
                            [#:Subject (U False String)] -> JSExpr))
(define (send-single-email server-token #:From from #:To to #:Body text
                           #:Subject [subject #f])
  (when (string=? text "")
    (raise-argument-error 'send-email
                          "non-empty text string"
                          3 server-token from to text subject))
  (: fields-assoc (Listof (Pairof Symbol String)))
  (define fields-assoc
    (append (cond [(string? subject) `((Subject . ,subject))]
                  [else `()])
            `((From . ,from)
              (To . ,to)
              (TextBody . ,text))))
  (postmark-post
   "/email"
   (list #"Content-Type: application/json"
         #"Accept: application/json"
         (server-token->header server-token))
   (make-hash fields-assoc)))

;; DELIVERY STATISTICS
(: deliverystats (Bytes -> JSExpr))
(define (deliverystats server-token)
  (postmark-get
   "/deliverystats"
   (list 
    (server-token->header server-token)
    #"Accept: application/json")))

;; get the text of the bounces
(: get-bounces (Bytes #:count Natural #:offset Natural -> JSExpr))
(define (get-bounces server-token
                     #:count count
                     #:offset offset)
  (postmark-get
   (string-append
    "/bounces?"
    (alist->form-urlencoded
     `((count . ,(number->string count))
       (offset . ,(number->string offset)))))
   (list 
    (server-token->header server-token)
    #"Accept: application/json")))

;; format the server token as a header line
;; e.g.: B7D4E => #"X-Postmark-Server-Token: B7D4E"
(: server-token->header (Bytes -> Bytes))
(define (server-token->header server-token)
  (bytes-append SERVER-TOKEN-TAG #": " server-token))


;; make a POST request to the Postmark API
(: postmark-post (String (Listof Bytes) JSExpr -> JSExpr))
(define (postmark-post endpoint headers data)
  (send-to-endpoint/inner #"POST" endpoint headers
                          (jsexpr->bytes data)))

;; make a GET request to the Postmark API
(: postmark-get (String (Listof Bytes) -> JSExpr))
(define (postmark-get endpoint headers)
  (send-to-endpoint/inner #"GET" endpoint headers #""))

;; legal HTTP methods:
(define-type Method (U #"GET" #"POST"))

;; send something to a Postmark endpoint. This is the common abstraction
;; for postmark-post and postmark-get
(: send-to-endpoint/inner (Method String (Listof Bytes) Bytes -> JSExpr))
(define (send-to-endpoint/inner method endpoint headers data)
  (: status-line Bytes)
  (: recv-headers (Listof Bytes))
  (: receive-port Input-Port)
  (define-values (status-line recv-headers receive-port)
    (http-sendrecv POSTMARK-HOST
                   endpoint
                   #:ssl? #t
                   #:headers headers
                   #:data data
                   #:method method))
  (match status-line
    [(regexp #px#"^HTTP/1.1 200")
     (define response-body (read-json receive-port))
     (cond [(eof-object? response-body)
            (error 'send-to-endpoint
                   "received empty response body from server")]
           [else response-body])]
    [(regexp #px#"^HTTP/1.1 ([0-9]+)" (list _1 num-str))
     (define response-body
       (match (regexp-match #px#".*" receive-port)
         [#f (error 'send-to-endpoint "internal-error 20150701")]
         [(list-rest bstr dontcare)
          (bytes->string/utf-8 bstr)]))
     ;; turns out it's not always JSON...
     #;(define response-body
       (~v (read-json receive-port)))
     (error 'send-to-endpoint
            "server was unhappy. Status line: ~e Response: ~e"
            status-line response-body)]
    [other (error 'send-to-endpoint "unexpected server status line: ~e"
                  status-line)]))

(module* test racket/base
  (require rackunit
           (submod ".."))
;; should complain about bogus body
(check-exn
 #px"422 Unprocessable Entity"
 (lambda ()
   (send-to-endpoint/inner
    #"POST"
    "/email"
    null
    #"123")))

(check-match
 (send-single-email TESTING-SERVER-TOKEN
                    #:From "bogus@illegal.com"
                    #:To "franky@illegal.com"
                    #:Body "XYZ")
 (hash-table (ErrorCode 0)
             (Message "Test job accepted")
             (To "franky@illegal.com")
             (dc1 dc2) ...)
 ))

;; postmark internal error??
#;(send-to-endpoint/inner
 #"GET"
 "/deliverystats"
 (list #"Accept: application/json"
       (server-token->header TESTING-SERVER-TOKEN))
 (jsexpr->bytes ""))

#;(deliverystats TESTING-SERVER-TOKEN)

