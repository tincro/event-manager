require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
        # strip non-integers
        # if phone < 10 digits == bad
        # if phone == 10, phone == good
        # if phone == 11 && phone[0] == '1', phone[1:]
        # if phone == 11 && phone[0] != 1, phone == bad
        # if phone > 11 digits, phone == bad
        phone = phone.delete(" ()-")

        if phone.length > 11 || phone.length < 10
            phone = nil.to_s
        elsif phone.to_s.start_with('1') && phone.length > 10
            phone.to_s[1..10]
        else
            phone.to_s[0..9]
        end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zip,
            levels: 'country', 
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials       
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'            
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'EventManager initialized!'

file = 'event_attendees.csv'

File.exist? csv_file
    contents = CSV.open(
        csv_file,
        headers: true,
        header_converters: :symbol
    )

    template_letter = File.read('form_letter.erb')
    erb_template = ERB.new template_letter

    contents.each do |row|
        id = row[0]
        name = row[:first_name]
        
        zipcode = clean_zipcode(row[:zipcode])

        phone = clean_phone(row[:homephone])
        
        legislators = legislators_by_zipcode(zipcode)
        
        form_letter = erb_template.result(binding)

        save_thank_you_letter(id, form_letter)
    end
