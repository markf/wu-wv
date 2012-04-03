#!/usr/bin/ruby

require 'rubygems'
require 'open-uri'
require 'json'

# US Zip or other API location, e.g. 'Australia/Syndey' or '<latitude>, <longitude>', etc.  See documentation.
$defaultlocation = '78701'
# Put your personal wunderground API key here
$wundergroundkey = ''
# Change this if desired
$tempunit = 'fahrenheit'
# Show probability of precipitation only if greater than or equal to this
$showpop = 10
# Public file location (css/icon images)
$weblocation = 'http://weather.mysite.com'
# Upload location for generated page
$filepath = '/usr/local/var/wview/img/forecast.htm'
# Radar image link
$radarurl = 'http://myradarimage.com'

# wunderground json grab
def getweather(somelocation)
  open("http://api.wunderground.com/api/#{$wundergroundkey}/forecast10day/q/#{somelocation}.json") do |f|
    json_string = f.read
    $weather_json = JSON.parse(json_string)
  end
end

# Get the forecast
getweather($defaultlocation)

fcttext = Array.new
icon = Array.new
pop = Array.new

if $weather_json['forecast']['txt_forecast']['forecastday'][0]['title'].include?("Night")
  icon.push(nil)
  fcttext.push(nil)
end

# get stats for the day/night (12 hr) portion of the output
for period in 0..11 do
  fcttext.push($weather_json['forecast']['txt_forecast']['forecastday'][period]['fcttext'])
  # wunderground has gone to using the same icon name for day/night but used to prepend with nt_
  if $weather_json['forecast']['txt_forecast']['forecastday'][period]['title'].include?("Night")
    dn_icon = "nt_" + $weather_json['forecast']['txt_forecast']['forecastday'][period]['icon']
  else
    dn_icon = $weather_json['forecast']['txt_forecast']['forecastday'][period]['icon']
  end
  icon.push(dn_icon)
  pop.push($weather_json['forecast']['txt_forecast']['forecastday'][period]['pop'])
end

weekday = Array.new
month = Array.new
day = Array.new
high = Array.new
low = Array.new
dayicon = Array.new

# get stats for the 24-hr portion of the output
for dayperiod in 0..6 do
  weekday.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['date']['weekday_short'])
  month.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['date']['monthname'][0..2])
  day.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['date']['day'])
  high.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['high'][$tempunit])
  low.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['low'][$tempunit])
  dayicon.push($weather_json['forecast']['simpleforecast']['forecastday'][dayperiod]['icon'])
end

# write the forecast HTML

f = File.new($filepath, "w")
f.print "
<!DOCTYPE html>

<head>
  <title>Forecast</title>
  <meta name='viewport' content='width=device-width; initial-scale=1.0; minimum-scale=1.0; maximum-scale=1.0; user-scalable=no;'/>
  <style type='text/css' media='screen'>@import '#{$weblocation}forecast.css';</style>
</head>

<body onload='setTimeout(function() { window.scrollTo(0, 1) }, 100);'>
<div id ='container'>
"
  for i in 0..3 do
    j = 2*i
    f.print "
    <div class='forecast'>
      <span class='date'>
        #{weekday[i]} #{month[i]} #{day[i]}
      </span>"
    unless icon[i].nil?
      f.print "
      <img class='day' src=#{$weblocation}#{icon[j]}.png>
      <span class='forecasthigh'>#{high[i]}&deg</span>"
    end
    f.print "
    <img class='night' src=#{$weblocation}#{icon[j+1]}.png>
    <span class='forecastlow'>#{low[i]}&deg</span>"     
    if pop[j].to_i > $showpop
      f.print "
      <span class='popday'>
        #{pop[j]}%
      </span>"
    end
    if pop[j+1].to_i > $showpop
      f.print "
       <span class='popnight'>
         #{pop[j+1]}%
       </span>"
    end
    f.print "
    </div>"
  end

  for i in 4..5 do
    f.print "
    <div class='miniforecast'>
      <span class='date'>
        #{weekday[i]}
      </span>
      <img class='day' src=#{$weblocation}#{dayicon[i]}.png>
      <span class='minihigh'>
        #{high[i]}&deg
      </span>"
    if low[i] != ""
      f.print "
      <span class='minilow'>
        #{low[i]}&deg
      </span>"
    end
    if pop[i*2].to_i >= $showpop 
      f.print "
      <span class='minipop'>
        #{pop[i*2]}%
      </span>"
    end
    f.print "
    </div>"
  end
  
f.print "
  <div class='fiftylinks'>
		<a href=#{$radarurl}>
				Radar
		</a>
	</div>
	<div class='fiftylinks'>
		<a href='iPhone.htm'>
				Conditions
		</a>
	</div>
</div>
</body>
</html>"

