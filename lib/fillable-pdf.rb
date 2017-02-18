require 'rjb'
require 'securerandom'

# http://github.com/itext/itextpdf/releases/latest
EXT_PATH = File.expand_path('../ext', __dir__)
Rjb::load("#{File.join(EXT_PATH, 'itextpdf-5.5.9.jar')}:" \
          "#{File.join(EXT_PATH, 'bcprov-jdk15on-156.jar')}:" \
          "#{File.join(EXT_PATH, 'bcpkix-jdk15on-156.jar')}")


class FillablePDF

  # required Java imports
  BYTE_STREAM = Rjb::import('java.io.ByteArrayOutputStream')
  FILE_READER = Rjb::import('com.itextpdf.text.pdf.PdfReader')
  PDF_STAMPER = Rjb::import('com.itextpdf.text.pdf.PdfStamper')
  DOCUMENT_BUILDER_FACTORY = Rjb::import('javax.xml.parsers.DocumentBuilderFactory')
  INPUT_SOURCE = Rjb::import('org.xml.sax.InputSource')
  STRING_READER = Rjb::import('java.io.StringReader')

  FILE_READER.unethicalreading = true

  ##
  # Opens a given fillable PDF file and prepares it for modification.
  #
  #   @param [String] file the name of the PDF file or file path
  #
  def initialize(file)
    @file = file
    @file_reader = FILE_READER.new(@file)
    @byte_stream = BYTE_STREAM.new
    @pdf_stamper = PDF_STAMPER.new @file_reader, @byte_stream, 0, true
    @form_fields = @pdf_stamper.getAcroFields
    @xfa = @form_fields.getXfa
  end


  ##
  # Determines whether the form has any fields.
  #
  #   @return true if form has fields, false otherwise
  #
  def has_fields?
    num_fields > 0
  end


  ##
  # Returns the total number of form fields.
  #
  #   @return the number of fields
  #
  def num_fields
    @form_fields.getFields.size
  end

  def get_fields
    @fields ||= begin
      fields = []
      iterator = @form_fields.getFields.keySet.iterator

      while iterator.hasNext
        fields << iterator.next.toString
      end

      fields
    end
  end

  ##
  # Retrieves the value of a field given its unique field name.
  #
  #   @param [String] key the field name
  #
  #   @return the value of the field
  #
  def get_field(key)
    @form_fields.getField key.to_s
  end


  ##
  # Sets the value of a field given its unique field name and value.
  #
  #   @param [String] key the field name
  #   @param [String] value the field value
  #
  def set_field(key, value)
    @form_fields.setField key.to_s, value.to_s
  end


  ##
  # Sets the values of multiple fields given a set of unique field names and values.
  #
  #   @param [Hash] fields the set of field names and values
  #
  def set_fields(fields)
    fields.each { |key, value| set_field key, value }
  end

  def fill_xfa_form(xml, read_only = false)
    @xfa.fillXfaForm(convert_xml_to_document(xml).getDocumentElement, read_only)
  end

  ##
  # Overwrites the previously opened PDF file and flattens it if requested.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save(flatten = false)
    tmp_file = SecureRandom.uuid
    save_as(tmp_file, flatten)
    File.rename tmp_file, @file
  end


  ##
  # Saves the filled out PDF file with a given file and flattens it if requested.
  #
  #   @param [String] file the name of the PDF file or file path
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def save_as(file, flatten = false)
    File.open(file, 'wb') { |f| f.write finalize flatten and f.close }
  end


  private

  ##
  # Writes the contents of the modified fields to the previously opened PDF file.
  #
  #   @param [bool] flatten true if PDF should be flattened, false otherwise
  #
  def finalize(flatten)
    @pdf_stamper.setFormFlattening flatten
    @pdf_stamper.close
    @file_reader.close
    @byte_stream.toByteArray
  end

  def convert_xml_to_document(xml)
    @factory ||= DOCUMENT_BUILDER_FACTORY.newInstance
    @factory.setNamespaceAware(true)
    @builder ||= @factory.newDocumentBuilder

    @builder.parse(INPUT_SOURCE.new(STRING_READER.new(xml)))
  end
  
end
