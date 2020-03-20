module FrequenciesHelper
  def valid_frequencies
    t("frequencies").map { |frequency, _config| frequency.to_s }
  end

  def frequencies(options = {})
    t("frequencies").map { |frequency, desc|
      {
        value: frequency,
        text: desc,
        checked: (options[:checked_frequency] == frequency.to_s),
      }
    }
  end

  def frequency_options(topic_id)
    options = {}
    if topic_id == "coronavirus-covid-19-uk-government-response"
      options[:checked_frequency] = "daily"
    end
    options
  end
end
