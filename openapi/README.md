# MTU API description

The OpenAPI 3.1 description of the campaign API, split by domain so no one file
gets unwieldy. `OpenapiBundle` merges these files into the single document
served at `/api/openapi.yml`, which is what the docs page at `/api` renders.

```
openapi.yml                       info, servers, tags, security
paths/<domain>.yml                path items, keyed by path (one file per tag)
components/parameters.yml         reusable parameters
components/responses.yml          reusable responses
components/security_schemes.yml   security schemes
components/schemas/<domain>.yml   schemas, keyed by name
```

## Adding or changing an endpoint

1. Add the path to `paths/<domain>.yml`, using the domain's tag. A new domain
   needs its tag in `openapi.yml` and a new file; files are picked up
   automatically.
2. Put response shapes in `components/schemas/<domain>.yml` and refer to them
   with `$ref: '#/components/schemas/Name'`. Reusable parameters and responses
   go in their own files.
3. Write or extend a controller test that hits the endpoint. Every request and
   response in the test suite is validated against the bundled document, so a
   response that does not match the spec fails the test.
4. Run `bin/rails test`. `coverage/openapi_coverage.html` lists documented
   operations and responses that no test exercised.

## Rules

- Paths are relative to the server URL, `/c/{campaign_slug}/api`.
- References are always internal (`#/components/...`) even across files, because
  the files are merged, not resolved. A name defined in two files is an error.
- Keep a name's schema in the file for the domain that owns it; shared basics
  (`Error`, `Roll`, `SystemRef`) live in `schemas/common.yml`.
- Nullable fields use `type: [string, 'null']`.
- `OpenapiBundleTest` checks that every `$ref` resolves and every operation uses
  a declared tag.
