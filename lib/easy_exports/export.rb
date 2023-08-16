# frozen_string_literal: true

module EasyExports
  class Export
    attr_reader :data, :csv_string

    def initialize(exported_data, exported_data_csv_string)
      @data = exported_data
      @csv_string = exported_data_csv_string
    end
  end
end
