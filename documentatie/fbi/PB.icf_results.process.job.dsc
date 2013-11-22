######################################################################
# File: PB.icf_results.process.job.dsc                               #
#                                                                    #
# This sample document-properties rules file specifies how to map    #
# values in a Pitney Bowes inserter results file to InfoPrint        #
# ProcessDirector job-property values.                               #
#                                                                    #
# To edit the rules file for your inserter, copy it to directory     #
# /aiw/aiw1/config/fbi/ and edit it. You can rename it; however the  #
# extension must be .dsc. Specify the full path name of the file in  #
# the "Job-properties rules file" property of the inserter           #
# controller object.                                                 #
#                                                                    #
# Format: Each statement (line) in the rules file specifies how to   #
# set an InfoPrint ProcessDirector document property:                #
#                                                                    #
# property_name,property_type,property_length,[expr=expression]      #
#                                                                    #
# property_name                                                      #
#   Specifies the database name of an InfoPrint ProcessDirector      #
#   job property.                                                    #
#   Note: To specify job properties other than Job.Inserter.ID and   #
#   Job.Name, first add the job property to this configuration file: #
#   /aiw/aiw1/config/fbi/icf_job_del_properties.cfg                  #
# property_type                                                      #
#   Specifies the type of data in the property value. Allowed values #
#   are: character, varchar, integer, bigint.                        #
# property_length                                                    #
#   Specifies the number of characters that the property allows in   #
#   the value.                                                       #
# [expr=expression]                                                  #
#   An expression in the Content Expression Language (CEL) that      #
#   specifies what value to set in the property. You can specify a   #
#   fixed value (such as blanks or zeroes), or you can specify       #
#   the value of a field in the results file. You can also use CEL   #
#   functions.                                                       #
#                                                                    #
# Note: For more information about inserter rules files and CEL, see #
#       the InfoPrint ProcessDirector information center.            #
#                                                                    #
######################################################################
#
#
######################################################################
# The next statement sets the Job.Inserter.ID property equal to the  #
# the value in the MachineID field of the first record in the        #
# inserter results file. The parsing rules file defines the location #
# of the MachineID field in the record.                              #
######################################################################
Job.Inserter.ID,varchar,255,[expr="DC Verify"]
Job.RequestedPrinter,character,1,[expr="#"]

