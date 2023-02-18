#
#  2022/12/17 - cp - This is going to be a pain in the rear.  IJ45056 is a 
#		replacement for the IJ42339 ifix, but it won't install when
#		IJ42339 is present, so we have to remove that one first.
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij42339_remover {

    #  This only applies to AIX and maybe VIOS in later versions
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ42339'

        #  Make sure we create/manage the ifix staging directory
        require profile::aix_file_opt_ifixes

        #
        #  For now, we're skipping anything that reads as a VIO server.
        #  We have no matching versions of this ifix / VIOS level installed.
        #
        unless ($::facts['aix_vios']['is_vios']) {

            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['kernelrelease'] == '7200-05-02-2114') {
                $ifixSuffix = 's2a'
                $ifixBuildDate = '220909'
            }
            else {
                if ($::facts['kernelrelease'] in ['7200-05-03-2148', '7200-05-04-2220']) {
                    $ifixSuffix = 's4a'
                    $ifixBuildDate = '220907'
                }
                else {
                    if ($::facts['kernelrelease'] == '7200-05-05-2246') {
                        $ifixSuffix = 's5a'
                        $ifixBuildDate = '221212'
                    }
                    else {
                        $ifixSuffix = 'unknown'
                        $ifixBuildDate = 'unknown'
                    }
                }
            }

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
            if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

                #
                #  2023/02/17 - cp - This is where things change for the remover.  We 
                #               only do the work if it *IS* present instead of absent.
                #
                if ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                    #  Build up the complete name of the ifix staging target
                    $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                    #  Remove the staged file from the previous ifix
                    file { "$ifixStagingTarget" :
                        ensure  => 'absent',
                    }

                    #  GAG!  Use an exec resource to remove it, since we have no other option yet
                    exec { "emgr-remove-${ifixName}":
                        path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                        command  => "/usr/sbin/emgr -r -L $ifixFullName",
                    }

                }

            }

        }

    }

}
