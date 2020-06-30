needs "Standard Libs/Units"
needs "Collection Management/CollectionDisplay"

module Pipettors

  include Units

  # opts: [Hash] default {}, single channel pipettor
  def pipet(volume:, source:, destination:, type: nil)
    pipettor = get_single_channel_pipettor(volume: volume,
                                           type: type)
    pipettor.pipet(
      volume: volume,
      source: source,
      destination: destination
    )
  end

  def multichannel_pipet(volume:, source:, destination:, type: nil)
    pipettor = get_multi_channel_pipettor(volume: volume, type: type)
    pipettor.pipet(
      volume: volume,
      source: source,
      destination: destination,
      association_map: association_map
    )
  end

  def get_single_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]
    if type == P2::NAME || qty <= 2
      P2.instance
    elsif type == P20::NAME || qty <= 20
      P20.instance
    elsif type == P200::NAME || qty <= 200
      P200.instance
    elsif type == P1000::NAME || qty <= 1000
      P1000.instance
    elsif qty <= 2000
      P1000.instance
    elsif type == PipetController::NAME || qty > 2000
      PipetController.instance
    end
  end

  def get_multi_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]
    if type == L8200XLS::NAME || qty <= 200
      L8200XLS.instance
    elsif type == LA61200XLS::NAME || qty <= 1000
      LA61200XLS.instance
    end
  end

  # TODO add comment
  class Pipettor
    include Singleton
    include Units

    def pipet(volume:, source:, destination:)
      max_volume = self.class::MAX_VOLUME
      if volume[:qty] <= max_volume
        qty = volume[:qty].round(self.class::ROUND_TO)
        "Using a #{self.class::NAME}, pipette #{qty_display(volume)} from #{source} into #{destination}"

      elsif volume[:qty] <= 2 * max_volume
        volume[:qty] = (volume[:qty] / 2.0).round(self.class::ROUND_TO)
        "Using a #{self.class::NAME}, pipette #{qty_display(volume)} TWICE from #{source} into #{destination}"
      end
    end
  end

  class MultiPipettor
    include Singleton
    include Units
    include CollectionDisplay

    def pipet(volume:, source:, destination:, association_map:)
      max_volume = self.class::MAX_VOLUME
      twice = false
      volume[:qty] = volume[:qty].round(self.class::ROUND_TO)

      if volume[:qty] <= 2 * max_volume && volume[:qty] >= max_volume
        twice = true
        volume[:qty] = (volume[:qty] / 2.0).round(self.class::ROUND_TO)
      elsif volume[:qty] >= 2 * max_volume
        raise 'It is not recommended to repeat pipet steps more than two times'
      end

      double = twice ? 'TWICE' : ''
      "Using a #{self.class::NAME}, pipette #{qty_display(volume)} #{double} from #{source}, #{destination}"
    end

    def channels
      self.class::CHANNELS
    end
  end

  class LA61200XLS < MultiPipettor
    NAME = 'Multi Channel Adjustable Space LA6 1200 Pipette'.freeze
    MIN_VOLUME = 200.0
    MAX_VOLUME = 1000.0
    ROUND_TO = 0
    CHANNELS = 6
  end

  class L8200XLS < MultiPipettor
    NAME = 'Multi Channel L8 200XLS Pipette'.freeze
    MIN_VOLUME = 20.0
    MAX_VOLUME = 200.0
    ROUND_TO = 0
    CHANNELS = 8
  end

  class P2 < Pipettor
    NAME = 'P2 Pipette'.freeze
    MIN_VOLUME = 0.0
    MAX_VOLUME = 2.0
    ROUND_TO = 1
  end

  class P20 < Pipettor
    NAME = 'P20 Pipette'.freeze
    MIN_VOLUME = 2.0
    MAX_VOLUME = 20.0
    ROUND_TO = 1
  end

  class P200 < Pipettor
    NAME = 'P200 Pipette'.freeze
    MIN_VOLUME = 20.0
    MAX_VOLUME = 200.0
    ROUND_TO = 0
  end

  class P1000 < Pipettor
    NAME = 'P1000 Pipette'.freeze
    MIN_VOLUME = 200.0
    MAX_VOLUME = 1000.0
    ROUND_TO = 0
  end

  class PipetController < Pipettor
    NAME = 'Pipet controller'.freeze
    MIN_VOLUME = 2000.0
    MAX_VOLUME = 50000.0
    ROUND_TO = 0
  end

end