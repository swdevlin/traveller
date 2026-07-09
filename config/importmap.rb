# Pin npm packages by running ./bin/importmap

pin 'application'
pin 'starmap'
pin 'theme'
pin '@hotwired/turbo-rails', to: 'turbo.min.js'
pin '@hotwired/stimulus', to: '@hotwired--stimulus.js' # @3.2.2
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
pin '@rails/actioncable', to: 'actioncable.esm.js'
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'ultimate_turbo_modal' # @3.0.4
