#lang scribble/manual

@title{Postmark}

@author[(author+email "John Clements" "clements@racket-lang.org")]

@(require (for-label "main.rkt"))

@(define (linklink url)
   (link url url))

@defmodule[postmark]{This collection allows the use of the Postmark API.}

@link["http://www.postmarkapp.com/"]{Postmark} is an e-mail
delivery service.

The Postmark API uses a REST interface, via HTTP.

In order to
use Postmark, users must sign up with Postmark to obtain credentials.
(Postmark is not free; as of 2015-11, it costs about 1/8 of a cent to
send an email to a single recipient.)

This interface is incredibly thin; adding new calls is super-simple.
In fact, the abstract-o-matic inside me wants to simplify all of this
to a simple declarative api-specification-language.

For more information on the API, see
@linklink["http://developer.postmarkapp.com/"]

@defproc[(send-single-email [server-api-key bytes?]
                            [#:From from string?]
                            [#:To to string?]
                            [#:Body body string?]
                            [#:Subject subject (or/c string? #f) #f]) jsexpr?]{
Sends a single e-mail. Use a comma-separated string for multiple
recipients. Use the server-api-key supplied by Postmark.
}

@defproc[(deliverystats [server-api-key bytes?]) jsexpr?]{
Return delivery statistics for the server associated with the API
key.
}

@defproc[(get-bounces [server-api-key bytes?]
                      [#:count count natural?]
                      [#:offset offset Natural?]) jsexpr?]{
Gets the text of bounced messages from an ordered list stored by the
server. The @racket[count] indicates
the maximum number of bounced messages to be obtained, and
@racket[offset] indicates the point in the ordered list at which
the server starts returning messages.}


