#lang scribble/manual

@title{Postmark}

@author[(author+email "John Clements" "clements@racket-lang.org")]

@(require (for-label "main.rkt"))

@defmodule[postmark]{This collection allows the use of the Postmark API.}

@link["http://www.postmarkapp.com/"]{Postmark}Postmark is an e-mail
delivery service.

The Postmark API uses a REST interface, via HTTP.

In order to
use Postmark, users must sign up with Postmark to obtain credentials.


@defproc[(send-single-email [server-api-key bytes?]
                            [#:From from string?]
                            [#:To to string?]
                            [#:Body body string?]) jsexpr?]{
Sends a single e-mail. Use a comma-separated string for multiple
recipients.
}

@defproc[(send-to-endpoint [endpoint String]
                           [headers (listof bytes?)]
                           [data jsexpr?]) jsexpr?]{
Sends a jsexpr to a given endpoint (of the
postmark host) using the given headers and the method "POST".

This is the backing abstraction for other functions.

}
