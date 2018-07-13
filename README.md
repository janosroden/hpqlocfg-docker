# hpqlocfg-docker
Run hpqlocfg in docker without using hp-ilo (cpqcidrv)

> The Lights-Out Configuration Utility (HPQLOCFG.EXE) is a Windows®-based utility that connects to iLO 3, iLO 4 or iLO 5 using a secure connection over the network. RIBCL scripts are passed over the secure connection to HPQLOCFG. This utility requires a valid user ID and password with the appropriate privileges.

*Source: https://support.hpe.com/hpsc/swd/public/detail?sp4ts.oid=1009143853&swItemId=MTX_8abe539b67bf46978e8f84acb8&swEnvOid=4184*

In order to avoid using kernel driver in docker I used the windows executable with wine.

## How to use

    docker run --rm -it -v $PWD/commands:/commands -e ILO_SERVER=<ip> -e ILO_USER=<user> -e ILO_PASSWORD="<password>" janosroden/hpqlocfg -f /commands/power_state.ribcl --xpath "string(//@HOST_POWER)"

## Extra features

- Specify default server, user and password as environment variables (you can override them in arguments)
- Use `-f -` to read from stdin
- You can use files which don't have `.xml` extension
- You can use `--xpath <xpath>` to extract data

## Exmaple usage

Derive from this image and replace the entrypoint with:

```bash
#!/bin/bash
# RIBLCL doc: https://support.hpe.com/hpsc/doc/public/display?docId=c03334058

####################################
### Host power status
####################################

# params: none
function getHostPowerStatus {
    cat << EOF | hpqlocfg -f - --xpath "string(//@HOST_POWER)"
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="adminname" PASSWORD="password">
    <SERVER_INFO MODE="read">
      <GET_HOST_POWER_STATUS/>
    </SERVER_INFO>
  </LOGIN>
</RIBCL>
EOF
}
function isPoweredOn { [[ $(getHostPowerStatus) = ON ]]; }
function isPoweredOff { [[ $(getHostPowerStatus) = OFF ]]; }

# params: <Yes|No>
function _setHostPowerStatus {
  cat << EOF | hpqlocfg -f - --xpath "string((//RESPONSE/@MESSAGE)[4])"
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="adminname" PASSWORD="password">
    <SERVER_INFO MODE="write">
      <SET_HOST_POWER HOST_POWER="$1"/>
    </SERVER_INFO>
  </LOGIN>
</RIBCL>
EOF
}
function hostPowerOn { _setHostPowerStatus Yes; }
function hostPowerOff { _setHostPowerStatus No; }

####################################
### Virtual media
####################################

# params: <FLOPPY|CDROM>
function _getVirtualMediaStatus {
    cat << EOF | hpqlocfg -f -
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="adminname" PASSWORD="password">
    <RIB_INFO MODE="read">
      <GET_VM_STATUS DEVICE="$1"/>
    </RIB_INFO>
  </LOGIN>
</RIBCL>
EOF
}
function getFloppyStatus { _getVirtualMediaStatus FLOPPY; }
function getCdromStatus { _getVirtualMediaStatus CDROM; }
function isFloppyInserted { [[ $(getFloppyStatus | xmllint --xpath "string(//@IMAGE_INSERTED)" -) = YES ]]; }
function isCdromInserted { [[ $(getCdromStatus | xmllint --xpath "string(//@IMAGE_INSERTED)" -) = YES ]]; }

# params: <FLOPPY|CDROM> <url>
function _insertVirtualMedia {
    cat << EOF | hpqlocfg -f -
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="adminname" PASSWORD="password">
    <RIB_INFO MODE="write">
      <INSERT_VIRTUAL_MEDIA DEVICE="$1" IMAGE_URL="$2" />
    </RIB_INFO>
  </LOGIN>
</RIBCL>    
EOF
}
# params: <url>
function insertFloppy { _insertVirtualMedia FLOPPY "$1"; }
function insertCdrom { _insertVirtualMedia CDROM "$1"; }

# params: <FLOPPY|CDROM>
function _ejectVirtualMedia {
    cat << EOF | hpqlocfg -f -
<RIBCL VERSION="2.0">
  <LOGIN USER_LOGIN="adminname" PASSWORD="password">
    <RIB_INFO MODE="write">
      <EJECT_VIRTUAL_MEDIA DEVICE="$1"/>
    </RIB_INFO>
  </LOGIN>
</RIBCL>
EOF
}
function ejectFloppy { _ejectVirtualMedia FLOPPY; }
function ejectCdrom { _ejectVirtualMedia CDROM; }


echo Host power state: $(getHostPowerStatus)
```
