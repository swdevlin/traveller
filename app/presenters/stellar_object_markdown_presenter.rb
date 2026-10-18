module StellarObjectMarkdownPresenter
  PRESENTER_MAP = {
    TerrestrialPlanet => TerrestrialPlanetMarkdownPresenter,
    Moon              => MoonMarkdownPresenter,
    Planetoid         => PlanetoidMarkdownPresenter,
    GasGiant          => GasGiantMarkdownPresenter,
    PlanetoidBelt     => PlanetoidBeltMarkdownPresenter,
    Star              => StarMarkdownPresenter,
    Comet             => CometMarkdownPresenter
  }.freeze

  def self.for(stellar_object, campaign = nil)
    klass = PRESENTER_MAP.fetch(stellar_object.class, SimpleStellarObjectMarkdownPresenter)
    klass.new(stellar_object, campaign)
  end
end
