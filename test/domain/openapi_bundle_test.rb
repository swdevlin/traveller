# frozen_string_literal: true

require 'test_helper'
require 'json_schemer'

class OpenapiBundleTest < ActiveSupport::TestCase
  setup do
    @document = OpenapiBundle.document
  end

  test 'merges every domain file into one document' do
    assert_match(/\A3\.1/, @document['openapi'])
    assert_predicate @document.dig('info', 'title'), :present?
    assert @document['paths'].key?('/sectors')
    assert @document['paths'].key?('/star_systems/{id}')
    assert @document.dig('components', 'schemas').key?('Sector')
    assert @document.dig('components', 'parameters').key?('Id')
    assert @document.dig('components', 'responses').key?('Unauthorised')
    assert @document.dig('components', 'securitySchemes').key?('bearerToken')
  end

  test 'every internal reference resolves' do
    unresolved = refs(@document).reject { |ref| resolves?(ref) }

    assert_empty unresolved, "Unresolved $refs: #{unresolved.uniq.join(', ')}"
  end

  test 'every operation uses a declared tag' do
    declared = @document['tags'].map { |tag| tag['name'] }
    used = @document['paths'].values.flat_map { |item| item.values.filter_map { |op| op['tags'] if op.is_a?(Hash) }.flatten }

    assert_empty used.uniq - declared
  end

  test 'every example matches its schema' do
    openapi = JSONSchemer.openapi(@document)
    invalid = examples(@document).reject do |pointer, example|
      openapi.ref("#{pointer}/schema".gsub('{', '%7B').gsub('}', '%7D')).valid?(example)
    end

    assert_empty invalid.map(&:first), 'Examples that do not match their schema'
  end

  test 'serves yaml that parses back to the same document' do
    assert_equal @document, YAML.safe_load(OpenapiBundle.yaml)
  end

  private

  # [JSON pointer to the media type, example] for every media type with an example.
  def examples(node, pointer = '#')
    return [] unless node.is_a?(Hash) || node.is_a?(Array)

    found = node.is_a?(Hash) && node.key?('example') && node.key?('schema') ? [[pointer, node['example']]] : []
    children = node.is_a?(Hash) ? node : node.each_with_index.map { |value, index| [index, value] }
    found + children.flat_map { |key, value| examples(value, "#{pointer}/#{key.to_s.gsub('~', '~0').gsub('/', '~1')}") }
  end

  def refs(node)
    case node
    when Hash then node.flat_map { |key, value| key == '$ref' ? [value] : refs(value) }
    when Array then node.flat_map { |value| refs(value) }
    else []
    end
  end

  def resolves?(ref)
    return false unless ref.start_with?('#/')

    !@document.dig(*ref.delete_prefix('#/').split('/')).nil?
  end
end
