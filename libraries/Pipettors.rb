needs "Standard Libs/Units"

module Pipettors
    
    include Units
    
    def pipet(volume:, source:, destination:, type: nil)
        pipettor = get_pipettor(volume: volume, type: type)
        pipettor.pipet(
            volume: volume, 
            source: source, 
            destination: destination
        )
    end
    
    def get_pipettor(volume:, type: nil)
        qty = type.present? ? Float::INFINITY : volume[:qty]
        if type == P2::NAME || qty <= 2
            return P2.instance
        elsif type == P20::NAME || qty <= 20
            return P20.instance
        elsif type == P200::NAME || qty <= 200
            return P200.instance
        elsif type == P1000::NAME || qty <= 1000
            return P1000.instance
        elsif qty <= 2000
            return P1000.instance
        elsif type == PipetController::NAME || qty > 2000
            return PipetController.instance
        end
    end
    
    class Pipettor
        include Singleton
        include Units
        
        def pipet(volume:, source:, destination:)
            max_volume = self.class::MAX_VOLUME
            
            if volume[:qty] <= max_volume
                volume[:qty] = volume[:qty].round(self.class::ROUND_TO)
                "Using a #{self.class::NAME}, pipet #{qty_display(volume)} from #{source} into #{destination}"
                
            elsif volume[:qty] <= 2 * max_volume
                volume[:qty] = (volume[:qty] / 2.0).round(self.class::ROUND_TO)
                "Using a #{self.class::NAME}, pipet #{qty_display(volume)} TWICE from #{source} into #{destination}"
            end
        end
    end
    
    class P2 < Pipettor
        NAME = 'P2'
        MIN_VOLUME = 0.0
        MAX_VOLUME = 2.0
        ROUND_TO = 1
    end
    
    class P20 < Pipettor
        NAME = 'P20'
        MIN_VOLUME = 2.0
        MAX_VOLUME = 20.0
        ROUND_TO = 1
    end
    
    class P200 < Pipettor
        NAME = 'P200'
        MIN_VOLUME = 20.0
        MAX_VOLUME = 200.0
        ROUND_TO = 0
    end
    
    class P1000 < Pipettor
        NAME = 'P1000'
        MIN_VOLUME = 200.0
        MAX_VOLUME = 1000.0
        ROUND_TO = 0
    end
    
    class PipetController < Pipettor
        NAME = 'Pipet controller'
        MIN_VOLUME = 2000.0
        MAX_VOLUME = 50000.0
        ROUND_TO = 0
    end
    
end