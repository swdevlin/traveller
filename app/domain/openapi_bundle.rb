# frozen_string_literal: true

# Builds the single OpenAPI document served at /api/openapi.yml from the files
# in openapi/:
#
#   openapi.yml                      info, servers, tags, security
#   paths/<domain>.yml               path items, keyed by path
#   components/parameters.yml        reusable parameters, keyed by name
#   components/responses.yml         reusable responses, keyed by name
#   components/security_schemes.yml  security schemes, keyed by name
#   components/schemas/<domain>.yml  schemas, keyed by name
#
# Every $ref stays internal ('#/components/...'), so the files are simply
# merged; a name used in two files is an error rather than a silent override.
class OpenapiBundle
  ROOT = Rails.root.join('openapi')

  class DuplicateKeyError < StandardError; end

  class << self
    def document
      load_document
    end

    # The merged document as YAML, rebuilt only when a source file changes.
    def yaml
      stamp = files.map { |file| File.mtime(file) }.max
      @cache = nil unless @cache && @cache[:stamp] == stamp
      @cache ||= { stamp: stamp, yaml: load_document.to_yaml }
      @cache[:yaml]
    end

    def files
      Dir.glob(ROOT.join('**/*.yml')).sort
    end

    private

    def load_document
      document = read(ROOT.join('openapi.yml'))
      document['paths'] = merge('paths/*.yml', 'paths')
      document['components'] = {
        'securitySchemes' => merge('components/security_schemes.yml', 'securitySchemes'),
        'parameters' => merge('components/parameters.yml', 'parameters'),
        'responses' => merge('components/responses.yml', 'responses'),
        'schemas' => merge('components/schemas/*.yml', 'schemas')
      }
      document
    end

    def merge(pattern, label)
      Dir.glob(ROOT.join(pattern)).sort.each_with_object({}) do |file, merged|
        read(file).each do |key, value|
          raise DuplicateKeyError, "#{label} '#{key}' is defined twice (second in #{file})" if merged.key?(key)

          merged[key] = value
        end
      end
    end

    def read(file)
      YAML.safe_load_file(file) || {}
    end
  end
end
