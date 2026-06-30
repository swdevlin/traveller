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
      'data-[overlay=true]:backdrop:bg-(--color-bg)/80 data-[overlay=true]:backdrop:backdrop-blur-sm',
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
        'bg-gradient-to-b from-(--color-panel) to-(--color-panel-muted) ' \
        'text-left text-(--color-fg) shadow-2xl sm:my-8 sm:max-w-5xl ' \
        'border border-(--color-outline) ' \
        'ring-1 ring-(--color-highlight)/10'

    MODAL_MAIN_CLASSES =
      'group-data-[padding=true]:p-5 group-data-[padding=true]:pt-3 ' \
        'overflow-y-auto max-h-[75vh] ' \
        'text-(--color-fg)'

    MODAL_HEADER_CLASSES =
      'flex justify-between items-center w-full py-4 rounded-t ' \
        'border-(--color-outline) ' \
        'group-data-[header-divider=true]:border-b ' \
        'group-data-[header=false]:absolute group-data-[header=false]:inset-x-0 group-data-[header=false]:top-0'

    MODAL_TITLE_CLASSES = 'pl-5'

    MODAL_TITLE_H_CLASSES =
      'group-data-[title=false]:hidden text-lg font-semibold tracking-wide text-(--color-highlight)'

    MODAL_FOOTER_CLASSES =
      'flex p-4 rounded-b border-(--color-outline) ' \
        'bg-(--color-bg)/40 ' \
        'group-data-[footer-divider=true]:border-t'

    MODAL_CLOSE_CLASSES = 'mr-4 group-data-[close-button=false]:hidden'

    MODAL_CLOSE_SR_CLASSES = 'sr-only'

    MODAL_CLOSE_BUTTON_CLASSES =
      'text-(--color-fg-muted) bg-(--color-bg)/30 border border-(--color-outline) ' \
        'hover:bg-(--color-bg)/60 hover:text-(--color-fg-bright) hover:border-(--color-highlight)/40 ' \
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-(--color-highlight)/50 focus-visible:ring-offset-2 focus-visible:ring-offset-(--color-bg) ' \
        'rounded-xl text-sm p-2 ml-auto inline-flex items-center transition'

    MODAL_CLOSE_ICON_CLASSES = 'w-5 h-5'

    # Drawer constants

    DRAWER_DIALOG_CLASSES = [
      'group',
      'fixed inset-0 p-0 m-0 border-none bg-transparent',
      'max-w-[100vw] max-h-dvh w-full h-full overflow-y-auto',
      'data-[overlay=true]:backdrop:bg-(--color-bg)/80 data-[overlay=true]:backdrop:backdrop-blur-sm',
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
        'bg-(--color-bg) border-l border-(--color-outline) ' \
        'group-data-[padding=true]:pt-6 shadow-xl text-(--color-fg)'

    DRAWER_HEADER_CLASSES =
      'flex items-start justify-between w-full px-4 sm:px-6 ' \
        'group-data-[header-divider=true]:pb-4 group-data-[header-divider=true]:border-b ' \
        'group-data-[header-divider=true]:border-(--color-outline) group-data-[header=false]:hidden'

    DRAWER_TITLE_CLASSES = ''

    DRAWER_TITLE_H_CLASSES =
      'group-data-[title=false]:hidden text-base font-semibold tracking-wide text-(--color-highlight)'

    DRAWER_MAIN_CLASSES =
      'relative group-data-[padding=true]:mt-6 flex-1 overflow-y-auto ' \
        'group-data-[padding=true]:px-4 group-data-[padding=true]:sm:px-6 group-data-[padding=true]:pb-6 ' \
        'text-(--color-fg)'

    DRAWER_FOOTER_CLASSES =
      'flex shrink-0 px-4 py-4 sm:px-6 ' \
        'group-data-[footer-divider=true]:border-t group-data-[footer-divider=true]:border-(--color-outline)'

    DRAWER_CLOSE_CLASSES = 'ml-3 flex h-7 items-center group-data-[close-button=false]:hidden'

    DRAWER_CLOSE_BUTTON_CLASSES =
      'relative rounded-xl text-(--color-fg-muted) ' \
        'hover:text-(--color-fg-bright) hover:bg-(--color-panel-muted) ' \
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-(--color-highlight)'

    DRAWER_CLOSE_SR_CLASSES = MODAL_CLOSE_SR_CLASSES

    DRAWER_CLOSE_ICON_CLASSES = 'size-6'
  end
end
