require 'rubygems'
require 'fastercsv'
require 'pony'

CSV_FILE = 'nbb_fcc_comments.csv'
DOCKET = '00-2000'
#TO_ADDRESS = 'alexanderkahn@gmail.com'
TO_ADDRESS = 'ecfs@fcc.gov'
TESTING_EMAIL = 'alexanderkahn@gmail.com'
TESTING_NAME = 'Alexander Kahn'

class FccComment
  attr_reader :comment

  def initialize(comment)
    @comment = comment
    @comment[:date] = format_date(@comment[:date])
    @comment[:name] = format_name
  end

  # Return a filled-in body
  def body
    body = <<-eot
ECFS - Email Filing
<PROCEEDING> #{DOCKET}
<DATE> #{@comment[:date]}
<NAME> #{@comment[:name]}
<ADDRESS1> #{@comment[:street]}
<ADDRESS2>
<CITY> #{@comment[:city]}
<STATE> #{@comment[:state]}
<ZIP> #{@comment[:zip]}
<LAW-FIRM>
<ATTORNEY>
<FILE-NUMBER>
<DOCUMENT-TYPE> CO
<PHONE-NUMBER>
<DESCRIPTION> Brief Comment
<CONTACT-EMAIL> #{contact_email}
<TEXT> #{@comment[:date]}

Ms. Marlene H. Dortch, Secretary
Federal Communications Commission
445 12th Street SW
Washington, DC  20554

Re: A National Broadband Plan for Our Future, GN Docket No. 09-51

Dear Ms. Dortch,
#{@comment[:text]}

    eot
  end

  # Send a properly formatted email to the FCC based on object's data
  def send_email
    mail = {
      :to => TO_ADDRESS,
      :from => from_email,
      :body => body,
      :subject => "Comment on Docket 09-51 from #{@comment[:name]}"
    }
    Pony.mail(mail)
  end

  private
    # Return a two-digit m/d/y date given a mixed date
    def format_date(date)
      date = DateTime.parse(date)
      date.strftime('%m/%d/%y')
    end

    # Return a full name given a first name and last name
    def format_name
      [@comment[:first], @comment[:last]].join(' ')
    end

    # Return a contact email address for testing or for a real activist
    def contact_email
      TESTING_EMAIL || @comment[:email]
    end

    # Returns a formatted name and email address for testing or for a real activist
    def from_email
      if TESTING_EMAIL
        return "#{TESTING_NAME} <#{TESTING_EMAIL}>" 
      else
        return "#{@comment[:name]} <#{@comment[:email]}>"
      end
    end
end


# Bring in the data
headers = [:last, :first, :street, :city, :state, :zip, :email, :date, :text]
csv = FasterCSV.read(CSV_FILE, { :headers => headers })

row_end = ARGV[0].to_i + ARGV[1].to_i - 1
range = Range.new(ARGV[0].to_i, row_end)

# Confirmation prompt
puts "Are you sure you want to send #{ARGV[1]} emails, starting at #{ARGV[0]}?"
puts "Sending to #{TO_ADDRESS} for docket #{DOCKET}"
execute = $stdin.gets

if ['y', 'Y', 'yes', 'Yes'].include?(execute.chomp)
  puts 'Sending emails...'
  # Send out emails according to range specified by arguments
  range.each do |i|
    comment = FccComment.new(csv[i].to_hash)
    if comment.send_email
      puts "Email #{i} (from #{comment.comment[:name]}) sent."
    else
      puts "Error at email #{i}."
    end
  end
else
  puts "Quitting..."
end
