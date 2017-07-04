module Stats
  class BaseReport


    def initialize
      raise "Cannot instantiate Stats::BaseReport - use derived class instead" if self.class == BaseReport
      @stats = nil                        # implement @stats as an instance of StatsCollector in derived class
      @first_column_heading = 'Teams'     # override in derived class if other heading required
      @superheadings = []                 # override in derived class if extra heading lines required in CSV
    end

    def self.title
      raise "#{self} doesn't implement .title method"
    end

    def self.description
      raise "#{self} doesn't implement .description method"
    end

    def results
      @stats.stats
    end

    def to_csv
      @stats.to_csv(@first_column_heading, @superheadings)
    end
  end
end