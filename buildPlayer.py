import os
import shutil
import sys
import subprocess

if (os.path.exists("/opt/flex")):
    flex = "/opt/flex"
    exe = ""
elif (os.path.exists(os.path.normpath("C:/flex_sdk_4.6"))):
    flex = ("C:/flex_sdk_4.6")
    exe = ".exe"

debug = "false"
swfversion = "17"
targetPlayer = "11.4.0"

if (len(sys.argv)>0 ):
    if (sys.argv[0] == "-debug"):
        debug = "true"
        swfversion = "18"
        targetPlayer = "11.5.0"
    else:
        print "incorrect argument"

print debug
print "-swf-version="+swfversion
print "-target-player="+targetPlayer

def popenPrint(result):
    result.wait()
    for line in result.stdout:
        print(line)
if ('sr-flash' not in os.getcwd()):
    os.chdir(os.path.normpath("sr-flash"))

#Compile worker
workerResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc" + exe),
                          "-compiler.source-path=.",
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-static-link-runtime-shared-libraries=true",
                          os.path.normpath("com/streamroot/TranscodeWorker.as"),
                          os.path.normpath("-output=com/streamroot/TranscodeWorker.swf"),
                          "-define+=CONFIG::LOGGING,false"],

                          stdout=subprocess.PIPE)

popenPrint(workerResult)
#Remove the old library before compiling the new as mxmlc doesn't support compling into non empty folder
if (os.path.exists("mse.swc")):
    os.remove("mse.swc")
#compile the library
libResult = subprocess.Popen([os.path.normpath(flex + "/bin/compc" + exe),
                          os.path.normpath("-compiler.source-path=."),
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-include-classes=com.streamroot.StreamrootInterfaceBase",
                          "-debug="+debug+"",
                          "-directory=false",
                          "-include-sources",
                          os.path.normpath("com/streamroot/StreamrootMSE.as"),
                          "-output=mse.swc"], stdout=subprocess.PIPE)
popenPrint(libResult)

#Moving the new library to the jwplayer and videojs folder
if (os.path.exists(os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))):
    os.remove("../streamroot-videojs/src/com/streamroot/mse.swc")
shutil.copyfile(os.path.normpath("mse.swc"),os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))
if (os.path.exists(os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))):
    os.remove(os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))
shutil.copyfile(os.path.normpath("mse.swc"),os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))

#Moving to the jwplayer folder and compiling jwplayer
os.chdir(os.path.normpath("../streamroot-jwplayer"))
jwpResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc" + exe),
                          os.path.normpath("src/flash/com/longtailvideo/jwplayer/player/Player.as"),
                          "-compiler.source-path=src/flash",
                          os.path.normpath("-compiler.library-path="+flex+"/frameworks/libs"),
                          "-static-link-runtime-shared-libraries=true",
                          os.path.normpath("-library-path=src/flash/com/streamroot/mse.swc"),
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-use-network=false",
                          os.path.normpath("-output=bin-release/jwplayer.flash.swf"),
                          "-compiler.optimize=true",
                          "-compiler.omit-trace-statements=true",
                          "-warnings=false",
                          "-define+=JWPLAYER::version,'6.11.20141118195350280'",
                          "-define+=CONFIG::debugging,"+debug+""], stdout=subprocess.PIPE)
popenPrint(jwpResult)
shutil.copy2(os.path.normpath("bin-release/jwplayer.flash.swf"),os.path.normpath("../sr-client-last/player_wrapper/jwplayer-wrapper/dist/6.8/jwplayer.srflash.swf"))

#Moving to the videojs folder and compiling videojs
os.chdir(os.path.normpath("../streamroot-videojs"))
vjsResult = subprocess.Popen([os.path.normpath(flex +"/bin/mxmlc" + exe),
                          os.path.normpath("src/com/videojs/VideoJS.as"),
                          "-compiler.source-path=src",
                          "-compiler.library-path="+flex+"/frameworks/libs",
                          os.path.normpath("-library-path=src/com/streamroot/mse.swc"),
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-use-network=false",
                          "-static-link-runtime-shared-libraries=true",
                          os.path.normpath("-output=dist/video-js-sr.swf"),
                          "-compiler.optimize=true",
                          "-compiler.omit-trace-statements=true",
                          "-warnings=false",
                          "-define+=CONFIG::version,\"'4.2.2'\""], stdout=subprocess.PIPE)
popenPrint(vjsResult)
shutil.copy2(os.path.normpath("dist/video-js-sr.swf"),os.path.normpath("../sr-client-last/player_wrapper/video-js-wrapper/video-js-sr.swf"))
print "Successfully built the flash engine swfs! Nice Job!"
