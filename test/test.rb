require_relative '../lib/fillable-pdf'

# opening a fillable PDF
pdf = FillablePDF.new('input.pdf')

# setting form fields
pdf.set_fields({first_name: 'Richard', last_name: 'Rahl'})
pdf.set_fields({football: 'Yes', baseball: 'Yes', basketball: 'Yes', nascar: 'Yes', hockey: 'Yes'})
pdf.set_field(:date, Time.now.strftime('%B %e, %Y'))

# saving the filled out PDF in another file and making it non-editable
pdf.save_as('output.pdf', true)

# total number of fields
if pdf.has_fields?
  puts "The form has a total of #{pdf.num_fields} fields."
else
  puts 'The form is not fillable.'
end

# printing the name of the person used inside the PDF
puts "To be signed by #{pdf.get_field(:first_name)} #{pdf.get_field(:last_name)}."