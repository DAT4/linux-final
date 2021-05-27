"""Send a reply from the proxy without sending any data to the remote server."""
from mitmproxy import http


def request(flow: http.HTTPFlow) -> None:
    print(flow.request.pretty_url)
    if 'google' in flow.request.pretty_url:
        flow.response = http.HTTPResponse.make(
            200,
            b"Hello sir, this is a con\n",
            {"Content-Type": "text/html"}
        )
