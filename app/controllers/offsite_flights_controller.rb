class OffsiteFlightsController < ApplicationController
  def redirect
    shortcut_flight = Flight.find(params[:id])
    original = params[:original] == "true"
    pure_search = params[:pure_search] == "true"
    departure_airport_code = shortcut_flight.departure_airport.code
    departure_date = shortcut_flight.departure_time.strftime('%m/%d/%Y')
    uid = ""
    itin_id = ""

    if original
      arrival_airport_code = shortcut_flight.arrival_airport.code
      search_result = search_result(departure_date, departure_airport_code, arrival_airport_code)
      flights = search_result["results"]
      rid = search_result["metadata"]["responseId"]

      flights.each do |flight|
        if flight["numberOfStops"].to_i == 0 && flight["airline"] == shortcut_flight.airline && flight["header"][0]["flightNumber"].to_i == shortcut_flight.flight_no.to_i
          uid = flight["uniqueId"]
          itin_id = flight["itinId"]
        end
      end
      link = link(departure_airport_code, arrival_airport_code, shortcut_flight, uid, itin_id, rid)

    elsif pure_search == true
      arrival_airport_code = shortcut_flight.arrival_airport.code
      link = pure_search_link(departure_airport_code, arrival_airport_code, shortcut_flight.departure_time)

    else
      arrival_airport_code = Airport.find(shortcut_flight.second_flight_destination).code
      search_result = search_result(departure_date, departure_airport_code, arrival_airport_code)
      flights = search_result["results"]
      rid = search_result["metadata"]["responseId"]

      flights.each do |flight|
        if flight["numberOfStops"].to_i == 1 && flight["header"][0]["flightNumber"].to_i == shortcut_flight.flight_no.to_i && flight["header"][1]["flightNumber"].to_i == shortcut_flight.second_flight_no.to_i
          uid = flight["uniqueId"]
          itin_id = flight["itinId"]
        end
      end
      link = link(departure_airport_code, arrival_airport_code, shortcut_flight, uid, itin_id, rid)
    end
    redirect_to link
  end

  def search_result(departure_date, departure_airport_code, arrival_airport_code)
    result = JSON.parse(RestClient.get 'http://travel.travelocity.com/flights/FlightsItineraryService.do', params: { jsessionid: 'ACEE3FCA20509BA3931D4E79C822E310.pwbap099a', flightType: 'oneway', dateTypeSelect: 'EXACT_DATES', leavingDate: departure_date, leavingFrom: departure_airport_code, goingTo: arrival_airport_code, dateLeavingTime: 1200, originalLeavingTime: 'Anytime', adults: 1, seniors: 0, children: 0, paxCount: 1, classOfService: 'ECONOMY', fareType: 'all', membershipLevel: 'NO_VALUE' })
  end

  def link(departure_airport_code, arrival_airport_code, flight, uid, itin_id, rid)
    "http://travel.travelocity.ca/flights/CrossSellCheckoutHandOff.do;jsessionid=E1F995747D3C4538FC8DA80BF226B3DF.pwbap033a?flightPath=TF&tripType=oneway#{(Time.now + 2.hours).to_s[0..18].gsub(/\D/,'')}&flightType=oneway&dateTypeSelect=exactDates&adults=1&children=0&minorsAge0=%3F&minorsAge1=%3F&minorsAge2=%3F&minorsAge3=%3F&minorsAge4=%3F&seniors=0&classOfService=ECONOMY&fareType=all&membershipLevel=NO_VALUE&airlineSearchPref=&leavingFrom=#{departure_airport_code}&goingTo=#{arrival_airport_code}&leavingDate=#{flight.departure_time.strftime('%m %d %Y').gsub(' ', '%2F')}&dateLeavingTime=Anytime&originalLeavingTime=Anytime&lastSelectedLeg=#{uid}&selectedLeg0=&selectedLeg1=&selectedLeg2=&itinId=#{itin_id}&rid=#{rid}&originalPrice=&originalTotalPrice="
  end

  def pure_search_link(departure_airport_code, arrival_airport_code, date)
    "http://travel.travelocity.ca/flights/InitialSearch.do?Service=TRAVELOCITY&last_pgd_page=ushpnbff.pgd&entryPoint=FD&pkg_type=fh_pkg&flightType=oneway&dateFormat=mm%2Fdd%2Fyyyy&subnav=form-fow&leavingFrom=#{departure_airport_code}&goingTo=#{arrival_airport_code}&dateTypeSelect=exactDates&leavingDate=#{date.strftime('%m %d %Y').gsub(' ', '%2F')}&dateLeavingTime=Anytime&departDateFlexibility=3&returningDate=mm%2Fdd%2Fyyyy&dateReturningTime=Anytime&returnDateFlexibility=3&adults=1&children=0&seniors=0&minorsAge0=%3F&minorsAge1=%3F&minorsAge2=%3F&minorsAge3=%3F&minorsAge4=%3F"
  end
end
