# frozen_string_literal: true

# Tailwind CSS v4
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    DIV_MODAL_CONTAINER_CLASSES = 'relative group z-50'

    # Backdrop: darker, slightly more “space fog”
    DIV_OVERLAY_CLASSES =
      'fixed inset-0 bg-slate-950/80 backdrop-blur-sm transition-opacity opacity-0'

    # Dialog wrapper: keep sizing, add a bit more breathing room on small screens
    DIV_DIALOG_CLASSES =
      'fixed inset-0 overflow-y-auto sm:max-w-[80%] md:max-w-3xl sm:mx-auto m-4 opacity-0'

    DIV_INNER_CLASSES =
      'flex min-h-full items-start justify-center pt-[10vh] sm:p-4'

    # Content shell: dark panel, orange edge glow, subtle “console” texture via gradient
    DIV_CONTENT_CLASSES =
      'relative transform max-h-screen overflow-hidden rounded-2xl ' \
        'bg-gradient-to-b from-slate-950/95 to-slate-950/80 ' \
        'text-left text-slate-100 shadow-2xl transition-all sm:my-8 sm:max-w-3xl ' \
        'border border-slate-700/60 ' \
        'ring-1 ring-deepnight-orange/10'

    # Body: keep padding behaviour, make scroll feel less like a white modal
    DIV_MAIN_CLASSES =
      'group-data-[padding=true]:p-5 group-data-[padding=true]:pt-3 ' \
        'overflow-y-auto max-h-[75vh] ' \
        'text-slate-200'

    # Header: sci-fi divider option, and if header=false (absolute) it still looks intentional
    DIV_HEADER_CLASSES =
      'flex justify-between items-center w-full py-4 rounded-t ' \
        'border-slate-700/60 ' \
        'group-data-[header-divider=true]:border-b ' \
        'group-data-[header=false]:absolute group-data-[header=false]:inset-x-0 group-data-[header=false]:top-0'

    DIV_TITLE_CLASSES = 'pl-5'

    DIV_TITLE_H_CLASSES =
      'group-data-[title=false]:hidden text-lg font-semibold tracking-wide text-slate-100'

    # Footer: same divider behaviour, slightly elevated surface
    DIV_FOOTER_CLASSES =
      'flex p-4 rounded-b border-slate-700/60 ' \
        'bg-slate-950/40 ' \
        'group-data-[footer-divider=true]:border-t'

    BUTTON_CLOSE_CLASSES = 'mr-4 group-data-[close-button=false]:hidden'

    BUTTON_CLOSE_SR_ONLY_CLASSES = 'sr-only'

    # Close button: console button vibe, orange hover, good focus ring
    CLOSE_BUTTON_TAG_CLASSES =
      'text-slate-400 bg-slate-950/30 border border-slate-700/60 ' \
        'hover:bg-slate-950/60 hover:text-slate-100 hover:border-deepnight-orange/40 ' \
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-deepnight-orange/50 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-950 ' \
        'rounded-xl text-sm p-2 ml-auto inline-flex items-center transition'

    ICON_CLOSE_CLASSES = 'w-5 h-5'

    TRANSITIONS = {
      overlay: {
        enter: {
          animation: 'ease-out duration-300',
          start: 'opacity-0',
          end: 'opacity-100'
        },
        leave: {
          animation: 'ease-in duration-200',
          start: 'opacity-100',
          end: 'opacity-0'
        }
      },
      dialog: {
        enter: {
          animation: 'ease-out duration-300',
          start: 'opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95',
          end: 'opacity-100 translate-y-0 sm:scale-100'
        },
        leave: {
          animation: 'ease-in duration-200',
          start: 'opacity-100 translate-y-0 sm:scale-100',
          end: 'opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95'
        }
      }
    }
  end
end
