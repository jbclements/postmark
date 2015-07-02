#lang typed/racket

;; some basic Postmark functionality.
;; NB: Uses only http-sendrecv, for simplicity.
;; keeping connections live would presumably
;; be more efficient for some applications.

(require typed/net/http-client
         typed/json
         typed/rackunit)

(provide send-single-email)

(define SERVER-TOKEN-TAG #"X-Postmark-Server-Token")
(define ACCOUNT-TOKEN-TAG #"X-Postmark-Account-Token")

(define TESTING-SERVER-TOKEN #"POSTMARK_API_TEST")

(define POSTMARK-HOST "api.postmarkapp.com")

;; SEND A SINGLE EMAIL

(define SINGLE-EMAIL-ENDPOINT "/email")

;; send a single email
(: send-single-email (String String String Bytes -> JSExpr))
(define (send-single-email from to text server-token)
  (send-to-endpoint
   SINGLE-EMAIL-ENDPOINT
   (list #"Content-Type: application/json"
         #"Accept: application/json"
         (bytes-append SERVER-TOKEN-TAG #": " server-token))
   (make-hash
    `((From . ,from)
      (To . ,to)
      (TextBody . ,text)))))


(: send-to-endpoint (String (Listof Bytes) JSExpr -> JSExpr))
(define (send-to-endpoint endpoint headers data)
  (: status-line Bytes)
  (: recv-headers (Listof Bytes))
  (: receive-port Input-Port)
  (define-values (status-line recv-headers receive-port)
    (http-sendrecv POSTMARK-HOST
                   endpoint
                   #:ssl? #t
                   #:headers headers
                   #:data (jsexpr->bytes data)
                   #:method #"POST"))
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


;; should complain about bogus body
(check-exn
 #px"422 Unprocessable Entity"
 (lambda ()
   (send-to-endpoint SINGLE-EMAIL-ENDPOINT
                     null
                     123)))

#;(send-single-email "bogus@illegal.com"
                      "franky@illegal.com"
                      "XYZ"
                      TESTING-SERVER-TOKEN)

