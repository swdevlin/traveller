// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import { UltimateTurboModalController } from "ultimate_turbo_modal"

application.register("modal", UltimateTurboModalController)
eagerLoadControllersFrom("controllers", application)
