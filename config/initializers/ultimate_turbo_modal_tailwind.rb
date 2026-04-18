# frozen_string_literal: true

# Tailwind CSS v4
module UltimateTurboModal::Flavors
  class Tailwind < UltimateTurboModal::Base
    STYLES = 'html:has(dialog#modal-container[open]) { overflow: hidden; }'

    # Modal constants

    MODAL_DIALOG_CLASSES = [
      'group',
      'fixed inset-0 p-0 m-0 border-none bg-transparent',
      'max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto',
      'data-[overlay=true]:backdrop:bg-slate-950/80 data-[overlay=true]:backdrop:backdrop-blur-sm',
      'backdrop:opacity-0 backdrop:transition-all backdrop:duration-300 backdrop:ease-out',
      'data-[entered]:data-[overlay=true]:backdrop:opacity-100',
      'data-[overlay=false]:backdrop:bg-transparent',
      'data-[closing]:backdrop:duration-200 data-[closing]:backdrop:ease-in'
    ].join(' ')

    MODAL_INNER_CLASSES = [
      'flex min-h-full items-start justify-center pt-[10vh] sm:p-4',
      'transition duration-200 ease-out',
      'group-data-[closing]:duration-150 group-data-[closing]:ease-in',
      'opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95',
      'group-data-[entered]:opacity-100 group-data-[entered]:translate-y-0 group-data-[entered]:scale-100'
    ].join(' ')

    MODAL_CONTENT_CLASSES =
      'relative max-h-screen overflow-hidden rounded-2xl ' \
        'bg-gradient-to-b from-slate-950/95 to-slate-950/80 ' \
        'text-left text-slate-100 shadow-2xl sm:my-8 sm:max-w-5xl ' \
        'border border-slate-700/60 ' \
        'ring-1 ring-deepnight-orange/10'

    MODAL_MAIN_CLASSES =
      'group-data-[padding=true]:p-5 group-data-[padding=true]:pt-3 ' \
        'overflow-y-auto max-h-[75vh] ' \
        'text-slate-200'

    MODAL_HEADER_CLASSES =
      'flex justify-between items-center w-full py-4 rounded-t ' \
        'border-slate-700/60 ' \
        'group-data-[header-divider=true]:border-b ' \
        'group-data-[header=false]:absolute group-data-[header=false]:inset-x-0 group-data-[header=false]:top-0'

    MODAL_TITLE_CLASSES = 'pl-5'

    MODAL_TITLE_H_CLASSES =
      'group-data-[title=false]:hidden text-lg font-semibold tracking-wide text-deepnight-orange'

    MODAL_FOOTER_CLASSES =
      'flex p-4 rounded-b border-slate-700/60 ' \
        'bg-slate-950/40 ' \
        'group-data-[footer-divider=true]:border-t'

    MODAL_CLOSE_CLASSES = 'mr-4 group-data-[close-button=false]:hidden'

    MODAL_CLOSE_SR_CLASSES = 'sr-only'

    MODAL_CLOSE_BUTTON_CLASSES =
      'text-slate-400 bg-slate-950/30 border border-slate-700/60 ' \
        'hover:bg-slate-950/60 hover:text-slate-100 hover:border-deepnight-orange/40 ' \
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-deepnight-orange/50 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-950 ' \
        'rounded-xl text-sm p-2 ml-auto inline-flex items-center transition'

    MODAL_CLOSE_ICON_CLASSES = 'w-5 h-5'

    # Drawer constants

    DRAWER_DIALOG_CLASSES = [
      'group',
      'fixed inset-0 p-0 m-0 border-none bg-transparent',
      'max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto',
      'data-[overlay=true]:backdrop:bg-slate-950/80 data-[overlay=true]:backdrop:backdrop-blur-sm',
      'backdrop:opacity-0 backdrop:transition-all backdrop:duration-300 backdrop:ease-out',
      'data-[entered]:data-[overlay=true]:backdrop:opacity-100',
      'data-[overlay=false]:backdrop:bg-transparent',
      'data-[closing]:backdrop:duration-200 data-[closing]:backdrop:ease-in',
      '[--utmr-gutter:2.5rem] sm:[--utmr-gutter:4rem]',
      'data-[drawer-size=xs]:[--utmr-w:16rem]',
      'data-[drawer-size=sm]:[--utmr-w:20rem]',
      'data-[drawer-size=md]:[--utmr-w:24rem]',
      'data-[drawer-size=lg]:[--utmr-w:28rem]',
      'data-[drawer-size=xl]:[--utmr-w:42rem]',
      'data-[drawer-size=2xl]:[--utmr-w:56rem]',
      'data-[drawer-size=full]:[--utmr-w:100vw]',
      'data-[drawer=left]:[--utmr-hide:-100%_0]',
      'data-[drawer=right]:[--utmr-hide:100%_0]'
    ].join(' ')

    DRAWER_WRAPPER_CLASSES = 'absolute inset-0 overflow-hidden'

    DRAWER_PANEL_CLASSES = [
      'absolute inset-y-0',
      'group-data-[drawer=left]:left-0 group-data-[drawer=right]:right-0',
      'w-[min(var(--utmr-w),calc(100vw_-_var(--utmr-gutter)))]',
      '[translate:var(--utmr-hide)]',
      'group-data-[entered]:[translate:0]',
      'group-data-[closing]:[translate:var(--utmr-hide)]',
      'transition-[translate] duration-250 ease-in-out sm:duration-400',
      'will-change-[translate]',
      'group-[&:not([data-enter-ready]):not([data-entered])]:invisible'
    ].join(' ')

    DRAWER_CONTENT_CLASSES =
      'relative flex h-full w-full flex-col ' \
        'bg-slate-950 border-l border-slate-700/60 ' \
        'group-data-[padding=true]:pt-6 shadow-xl text-slate-100'

    DRAWER_HEADER_CLASSES =
      'flex items-start justify-between w-full px-4 sm:px-6 ' \
        'group-data-[header-divider=true]:pb-4 group-data-[header-divider=true]:border-b ' \
        'group-data-[header-divider=true]:border-slate-700/60 group-data-[header=false]:hidden'

    DRAWER_TITLE_CLASSES = ''

    DRAWER_TITLE_H_CLASSES =
      'group-data-[title=false]:hidden text-base font-semibold tracking-wide text-deepnight-orange'

    DRAWER_MAIN_CLASSES =
      'relative group-data-[padding=true]:mt-6 flex-1 overflow-y-auto ' \
        'group-data-[padding=true]:px-4 group-data-[padding=true]:sm:px-6 group-data-[padding=true]:pb-6 ' \
        'text-slate-200'

    DRAWER_FOOTER_CLASSES =
      'flex shrink-0 px-4 py-4 sm:px-6 ' \
        'group-data-[footer-divider=true]:border-t group-data-[footer-divider=true]:border-slate-700/60'

    DRAWER_CLOSE_CLASSES = 'ml-3 flex h-7 items-center group-data-[close-button=false]:hidden'

    DRAWER_CLOSE_BUTTON_CLASSES =
      'relative rounded-xl text-slate-400 ' \
        'hover:text-slate-100 hover:bg-slate-900 ' \
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-deepnight-orange'

    DRAWER_CLOSE_SR_CLASSES = MODAL_CLOSE_SR_CLASSES

    DRAWER_CLOSE_ICON_CLASSES = 'size-6'
  end
end
