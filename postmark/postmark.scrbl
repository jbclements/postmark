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


