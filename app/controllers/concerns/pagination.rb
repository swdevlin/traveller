# frozen_string_literal: true

module Pagination
  extend ActiveSupport::Concern
  include Pagy::Backend
end
