class AttendeeCleaner
  INVALID_ZIPCODE = "00000"
  INVALID_PHONE_NUMBER = "0000000000"

  def self.clean_attribute(attribute, value)
    clean_method = "clean_#{attribute}".downcase
    if respond_to? clean_method
      value = send(clean_method, value)
    else
      value
    end
  end

  def self.clean_first_name(name)
    if name
      name.capitalize
    end
  end

  def self.clean_last_name(name)
    if name
      name.capitalize
    end
  end

  def self.clean_state(state)
    if state
      state.upcase
    end
  end

  def self.clean_city(city)
    if city
      if city.split.length < 1
        city.split.map{|c| c.capitalize}.join(" ")
      else
        city.capitalize
      end
    end
  end

  def self.clean_street(street)
    if street
      street.split.map!(&:capitalize).join(" ") #capitalize each word
    end
  end

  def self.clean_regdate(date)
    if date =~ @date_regex
        v = DateTime.strptime(date, DATEFORMAT)
    end
  end

  def self.clean_zipcode(zipcode)
    if zipcode && zipcode.length <= 5
      zipcode = zipcode.only_digits
      "%05d" % zipcode.to_i
    else
      INVALID_ZIPCODE
    end
  end

  def self.clean_homephone(num)
    num = num.only_digits

    if num.length == 10
      num
    elsif num.length == 11 && num.start_with?("1")
      num[1..-1]
    else
      INVALID_PHONE_NUMBER
    end
  end
end