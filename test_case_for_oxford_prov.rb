require 'nokogiri'

# change to the correct path to the desired collection xml files...
#files = Dir['/home/hellerb/Projects/medieval-mss/collections/Lyell/*.xml'].reject { |fn| fn.include? "empt" }

# set this to the Collections directory on your local host
TEI_DIR = "/Users/emeryr/code/GIT/medieval-mss/collections"
# All the collections folders to modify, separated by white space
COLLECTIONS = %w{ Arch_Selden Selden_superius Selden_supra }

files = COLLECTIONS.flat_map { |coll| Dir["#{TEI_DIR}/#{coll}/*.xml"].reject { |fn| fn.include? "empt" } }

files.each do |file|
  doc = Nokogiri::XML(open(file))

  puts "#{file} >>>     msParts: #{doc.search("msPart").count}, msParts WITH history: #{doc.css('msPart > history').count}, msDesc WITH history: #{doc.css('msDesc > history').count}"

  if (history = doc.css("msDesc > history").first)
    # pass
  else
    history = doc.create_element("history")
    doc.css("msDesc > additional").before(history)
    puts "Adding new HISTORY tag for: #{file}"
  end

  if history.search("acquisition").count > 0
    puts "Existing acquisition tag, skipping:  #{file}"
    next
  else
    provenance              = doc.create_element('provenance')
    provenance['notBefore'] = '1584'                                  # CHANGE
    provenance['notAfter']  = '1654'                                  # CHANGE
    provenance['resp']      = '#MMM'
    persName                = doc.create_element('persName')
    persName['role']        = 'formerOwner'
    persName['key']         = 'person_51728429'                       # CHANGE
    persName.content        = 'John Selden, 1584-1654'                # CHANGE
    provenance.add_child(persName)

    doc.at('history').add_child(provenance)

    acquisition             = doc.create_element('acquisition')
    acquisition['when']     = '1659'                                  # CHANGE
    acquisition['resp']     = '#MMM'
    acquisition.content     = 'Acquired by the Bodleian in 1659'      # CHANGE

    doc.at('history').add_child(acquisition)

    change                  = doc.create_element('change')
    change["when"]          = Time.now.strftime "%Y-%m-%d"
    change["xml:id"]        = "MMM"
    change.inner_html       = %q(Provenance and acquisition information added using <ref target=https://github.com/upenn-libraries/oxfordupdates/blob/master/test_case_for_oxford_prov.rb>https://github.com/upenn-libraries/oxfordupdates/blob/master/test_case_for_oxford_prov.rb</ref> in collaboration with the <ref target=http://mappingmanuscriptmigrations.org/>Mapping Manuscript Migrations</ref> project.')
    change_person           = doc.create_element('persName')
    change_person.content   = 'Toby Burrows/Mapping Manuscript Migrations' # CHANGE??
    change.prepend_child(change_person)

    doc.at('revisionDesc').prepend_child(change)
  end

  fp = open(file, 'w')
  fp.puts doc.to_xml
  fp.close
end