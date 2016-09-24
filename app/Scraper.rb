require 'HTTParty'
require 'Nokogiri'
require 'JSON'
require 'Pry'
require 'csv'
require 'Matrix'

 @@fftdata  = []

class FFToday
  @rshstats = []
  @recstats = []

  def self.designate_site(pageurl)
    page = HTTParty.get(pageurl)
    @page_parse = Nokogiri::HTML(page)
  end

  def self.site_parser(htmlobject, array)
    @page_parse.css(htmlobject).map do |row|
      text = row.text
      text.gsub!(' ', '')
      array << text.strip
    end
  end

  def self.cleanup(array)
    ranking = 1
    array.each do |row|
      row.slice!(0)
      row.insert(0, ranking)
      ranking += 1
    end
  end

  def self.pushtoarray(sitearray, fftparse)
    sitearray.each do |site, position, length|
      placeholder = []
      designate_site(site)
      site_parser(fftparse[0], placeholder)
      site_parser(fftparse[1], placeholder)
      cleanarray = placeholder.each_slice(length).to_a
      cleanarray.delete(cleanarray[0])
      cleanup(cleanarray)

      if position == 'QB'
        comp_pct     = []
        qbstatistics = Matrix[]
        cleanarray.each do |row|
          f_number = ((row[4].to_f / row[5].to_f) * 100).round(2)
          comp_pct << f_number.to_s + "%"
          rushingcalc(row[1], position, row[9], row[10], row[11])
        end
        @rshstats.each do |player|
          if player[1] == 'QB'
            qbstatistics = Matrix.rows(qbstatistics.to_a << player)
          end
        end
        dataarray = (cleanarray.transpose << comp_pct << qbstatistics.column(2).to_a << qbstatistics.column(3).to_a << qbstatistics.column(7).to_a << qbstatistics.column(8).to_a).transpose
        createarray(dataarray, position)
      elsif position == 'RB'
        rbstatistics = Matrix[]
        cleanarray.each do |row|
          rushingcalc(row[1], position, row[4], row[5], row[6])
        end
        @rshstats.each do |player|
          if player[1] == 'RB'
            rbstatistics = Matrix.rows(rbstatistics.to_a << player)
          end
        end
        dataarray = (cleanarray.transpose << rbstatistics.column(2).to_a << rbstatistics.column(3).to_a << rbstatistics.column(7).to_a << rbstatistics.column(8).to_a).transpose
        createarray(dataarray, position)
      elsif position == 'WR'
        wrstatistics = Matrix[]
        cleanarray.each do |row|
          rushingcalc(row[1], position, row[7], row[8], row[9])
        end
        @rshstats.each do |player|
          if player[1] == 'WR'
            wrstatistics = Matrix.rows(wrstatistics.to_a << player)
          end
        end
        puts @rshstats.inspect
        dataarray = (cleanarray.transpose << wrstatistics.column(2).to_a << wrstatistics.column(3).to_a << wrstatistics.column(7).to_a << wrstatistics.column(8).to_a).transpose
        createarray(dataarray, position)
      elsif position == 'TE'
        #Do Cleandata Position-Centric Calculations Here
        dataarray = cleanarray
        createarray(dataarray, position)
      end

    end
  end
      
  def self.rushingcalc(pname, position, attempts, yards, tds)
    @rshstats << [pname, position, ((yards.gsub(/,/, '').to_f / attempts.gsub(/,/, '').to_f).round(2)).to_s, ((attempts.gsub(/,/, '').to_f / 17).round(2)).to_s, attempts, yards, tds, ((tds.gsub(/,/, '').to_f / attempts.gsub(/,/, '').to_f) * 100).round(2).to_s + "%", ((tds.gsub(/,/, '').to_f / 17) * 100).round(2).to_s + "%"]
  end

  def self.receivingcalc(pname, position, attempts, yards, tds)
    @rshstats << [pname, position, ((yards.gsub(/,/, '').to_f / attempts.gsub(/,/, '').to_f).round(2)).to_s, ((attempts.gsub(/,/, '').to_f / 17).round(2)).to_s, attempts, yards, tds, ((tds.gsub(/,/, '').to_f / attempts.gsub(/,/, '').to_f) * 100).round(2).to_s + "%", ((tds.gsub(/,/, '').to_f / 17) * 100).round(2).to_s + "%"]
  end

  def self.createarray(array, position)
    array.each_with_index do |item, index|
      sequence = index + 1
      if position == 'QB'
        @@fftdata << [item[0], "QB#{sequence}", item[1], item[2], item[3], item[4], item[5], item[13], item[6], item[7], item[8], item[14], item[15], item[9], item[10], item[11], item[16], item[17], "0", "0", "0",item[12]]
      elsif position == 'RB'
        @@fftdata << [item[0], "RB#{sequence}", item[1], item[2], item[3], "0", "0", "0", "0", "0", "0",item[11], item[12], item[4], item[5], item[6], item[13], item[14], item[7], item[8], item[9], item[10]]
      elsif position == 'WR'
        @@fftdata << [item[0], "WR#{sequence}", item[1], item[2], item[3], "0", "0", "0", "0", "0", "0", item[11], item[12], item[7], item[8], item[9], item[13], item[14], item[4], item[5], item[6], item[10]]
      elsif position == 'TE'
        @@fftdata << [item[0], "TE#{sequence}", item[1], item[2], item[3], "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", item[4], item[5], item[6], item[7]]
      end
    end
  end

end

#AGNOSTIC FFTODAY HTML OBJECT SELECTORS
fftparse = ['b','.sort1']

fftsite = [['http://www.fftoday.com/rankings/playerproj.php?PosID=10&LeagueID=1', 'QB', 13],
           ['http://www.fftoday.com/rankings/playerproj.php?PosID=20&LeagueID=1', 'RB', 11],
           ['http://www.fftoday.com/rankings/playerproj.php?PosID=30&LeagueID=1', 'WR', 11],
           ['http://www.fftoday.com/rankings/playerproj.php?PosID=40&LeagueID=1', 'TE', 8]
          ]

FFToday.pushtoarray(fftsite, fftparse)

ffpparse = []

ffpsite = ['https://www.fantasypros.com/nfl/projections/qb.php?week=draft', 'QB', 11]]


CSV.open('ff.csv', 'w') do |csv|
  csv << ["Ranking", "PositionRanking", "PlayerName", "Team", "Bye", "PassComp", "PassAtt", "PassComp%", "PassYds", "PassTD", "PassINT", "YPC", "RshAttPG", "RshAtt", "RshYards", "RshTD", "TDperRshAtt", "TDperGame", "Rec", "RecYds", "RecTD", "FantasyPts"]
  @@fftdata.each do |row|
    csv << row
  end
end

