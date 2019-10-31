require 'nokogiri'

# Set COLLECTIONS_DIR to the collections directory in the medieval-mss
# repository on your local host.
COLLECTIONS_DIR = "/Users/emeryr/code/GIT/medieval-mss/collections"
# All the collection folders to modify, separated by white space.
# e.g., COLLECTIONS = %w{ Rawl_A Rawl_B Rawl_C Rawl_D Rawl_Essex Rawl_G Rawl_liturg Rawl_poet Rawl_Q Rawl_statutes }
COLLECTIONS = %w{ Barlow }

# for each collection; get the list of TEI files
files = COLLECTIONS.flat_map { |coll| Dir["#{COLLECTIONS_DIR}/#{coll}/*.xml"].reject { |fn| fn.include? "empt" } }

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

  # /TEI/teiHeader[1]/revisionDesc[1]
  if (revisionDesc = doc.css("teiHeader > revisionDesc").first)
    # pass
  else
    revisionDesc = doc.create_element("revisionDesc")
    # doc.css("msDesc > additional").before(history)
    doc.css("teiHeader > fileDesc").after(revisionDesc)
    puts "Adding new revisionDesc tag for: #{file}"
  end

  if history.search("acquisition").count > 0
    puts "Existing acquisition tag, skipping:  #{file}"
    next
  else
    provenance              = doc.create_element('provenance')
    provenance['notBefore'] = '1607'                                  # CHANGE
    provenance['notAfter']  = '1691'                                  # CHANGE
    provenance['resp']      = '#MMM'
    persName                = doc.create_element('persName')
    persName['role']        = 'formerOwner'
    persName['key']         = 'person_465'                            # CHANGE
    persName.content        = 'Thomas Barlow, 1607-1691'              # CHANGE
    provenance.add_child(persName)

    doc.at('history').add_child(provenance)

    acquisition             = doc.create_element('acquisition')
    acquisition['when']     = '1691'                                  # CHANGE
    acquisition['resp']     = '#MMM'
    acquisition.content     = 'Bequeathed to the Bodleian in 1691'    # CHANGE

    doc.at('history').add_child(acquisition)

    change                  = doc.create_element('change')
    change["when"]          = Time.now.strftime "%Y-%m-%d"
    change["xml:id"]        = "MMM"
    change.inner_html       = %q(Provenance and acquisition information added using <ref target=https://github.com/mapping-manuscript-migrations/oxford-tei-updates/blob/master/update_oxford_prov.rb>https://github.com/mapping-manuscript-migrations/oxford-tei-updates/blob/master/update_oxford_prov.rb</ref> in collaboration with the <ref target=http://mappingmanuscriptmigrations.org/>Mapping Manuscript Migrations</ref> project.)
    change_person           = doc.create_element('persName')
    change_person.content   = 'Toby Burrows/Mapping Manuscript Migrations' # CHANGE??
    change.prepend_child(change_person)

    revisionDesc.prepend_child(change)
  end

  fp = open(file, 'w')
  fp.puts doc.to_xml
  fp.close
end