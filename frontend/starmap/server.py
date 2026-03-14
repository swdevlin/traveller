import sys
import glob
import json
import pathlib
import argparse

from urllib.parse import urlparse, parse_qs
from functools import partial
from http.server import SimpleHTTPRequestHandler, HTTPServer
from typing import Callable

#try to use pretty_errors if installed
HAS_PRETTY_ERRORS = False
try:
	import pretty_errors # type: ignore
	pretty_errors.configure(
		lines_after = 2,
		lines_before= 2,
	)
	HAS_PRETTY_ERRORS = True
except ImportError:
	pass

parser = argparse.ArgumentParser(
	prog="Traveller dev server",
	description="serves the Traveller  files",
)

parser.add_argument("-p", "--port", default=12345)

class MyHandler(SimpleHTTPRequestHandler):
	def __init__(self, *args, **kwargs):
			super().__init__(*args, **kwargs)

	def get_query_params(self, path:str) -> dict[str, list[str]]:
		query = urlparse(path).query
		parsed_query = parse_qs(query)

		return parsed_query

	def json_response(self, json_str:str) -> None:
		self.send_response(200)
		self.send_header('Content-Type', 'application/json')
		self.send_header("Content-Length", str(len(json_str)))
		self.end_headers()

		self.wfile.write(json_str.encode(encoding='utf_8'))

	def string_response(self, plain_str:str) -> None:
		self.send_response(200)
		self.send_header('Content-Type', 'application/text')
		self.send_header("Content-Length", str(plain_str))
		self.end_headers()

		self.wfile.write(plain_str.encode(encoding='utf_8'))



	def do_GET(self)->None:
		parsed_path = urlparse(self.path)
		path = parsed_path.path.rstrip("/")
		print("path:", path)

		# NOTE: dont put trailing slashes in the keys
		routes = {
		}

		if path in routes:
			handler = routes[path]
			handler()
			return None

		allowed_extensions = tuple(["js", "jpg", "png", "json"])
		if not self.path.endswith(allowed_extensions):
			# Redirect all non-js requests to './index.html'
			self.path = "./index.html"

		return SimpleHTTPRequestHandler.do_GET(self)

class TravellerServer(HTTPServer):

	def handle_error(self, request, client_address):
		if HAS_PRETTY_ERRORS:
			pretty_errors.excepthook(*sys.exc_info())
		else:
			super().handle_error(request, client_address)



ERROR = '\033[91m'
WARNING = '\033[93m'
ENDC = '\033[0m'

if __name__ == "__main__":
	args = parser.parse_args()

	with TravellerServer(("", args.port), partial(MyHandler)) as httpd:
		print(f"Serving at port {args.port}")
		httpd.serve_forever(0.1)
