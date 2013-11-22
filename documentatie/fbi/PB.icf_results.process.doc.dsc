######################################################################
# File: PB.icf_results.process.doc.dsc                               #
#                                                                    #
# Dis bestand definieert wat er met de gelezen resultaten 
# gedaan moet worden.
#
######################################################################
######################################################################
Doc.ID,bigint,16,[expr=rtrim(ReprintIndex)]
######################################################################
# The next statement sets the Doc.Insert.OperatorID property equal   #
# to the value in the OperatorID field. The parsing rules file       #
# defines the location of the OperatorID field in each record.       #
######################################################################
#Doc.Insert.OperatorID,character,64,[expr=OperatorID]
######################################################################
# The next statement sets the Doc.Insert.Status property according   #
# to the value in the Disposition field:                             #
#                                                                    #
# If Disposition is:                 Set Doc.Insert.Status to:       #
# -----------------------            ----------------------------    #
# 6                                  null string                     #
# 2, 3, 4 or 7                       Damaged                         #
# 5 or 8                             OK                              #
# 9                                  Pulled                          #
# Anything else                      Attention                       #
#                                                                    #
# The parsing rules file defines the location of the                 #
# Disposition field in each record.                                  #
######################################################################
Doc.Insert.Status,character,16,[expr=if(Disposition==6,"",if(or(Disposition==2,Disposition==3,Disposition==4,Disposition==7),"Damaged",if(or(Disposition==5,Disposition==8),"OK",if(Disposition==9,"Pulled","Attention"))))]
######################################################################
# The next statement sets the Doc.Inserter.StatusCode property equal #
# to the value in the Disposition field. The parsing rules file      #
# defines the location of the Disposition field in each record.      #
######################################################################
Doc.Inserter.StatusCode,character,16,[expr=Disposition]
######################################################################
# The next statement sets the Doc.Inserter.StatusCodeExtended        #
# property equal to the value in the DispositionText field. The      #
# parsing rules file defines the location of the DispositionText     #
# field in each record.                                              #
######################################################################
#Doc.Inserter.StatusCodeExtended,character,128,[expr=DispositionText]
######################################################################
# The next statement sets the Doc.Insert.Sequence property equal     #
# to the value in the PieceID field. The parsing rules file defines  #
# the location of the PieceID field in each record.                  #
######################################################################
#Doc.Insert.Sequence,integer,8,[expr=PieceID]
