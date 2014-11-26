import os
import shutil
import sys
import subprocess

if (os.path.exists("/opt/flex")):
    flex = "/opt/flex"
elif (os.path.exists(os.path.normpath("C:/flex_sdk_4.6"))):
    flex=("C:/flex_sdk_4.6")

debug = "false"

if (len(sys.argv)>1 ):
    if (sys.argv[1] == "debug"):
        debug = "true"
    else:
        print "incorrect argument"

def popenPrint(result):
    result.wait()
    for line in result.stdout:
        print(line)

#Compile worker
workerResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc"),
                          "-compiler.source-path=.",
                          "-target-player=11.4.0",
                          "-swf-version=17",
                          "-static-link-runtime-shared-libraries=true",
                          os.path.normpath("com/streamroot/TranscodeWorker.as"),
                          os.path.normpath("-output=com/streamroot/TranscodeWorker.swf")], stdout=subprocess.PIPE)
popenPrint(workerResult)

#Remove the old library before compiling the new as mxmlc doesn't support compling into non empty folder
if (os.path.exists("mse.swc")):
    shutil.rmtree("mse.swc")
#compile the library
libResult = subprocess.Popen([os.path.normpath(flex + "/bin/compc"),
                          os.path.normpath("-compiler.source-path=."),
                          "-target-player=11.4.0",
                          "-swf-version=17",
                          "-directory=true",
                          "-include-sources",
                          os.path.normpath("com/streamroot/StreamrootMSE.as"),
                          "-output=mse.swc"], stdout=subprocess.PIPE)
popenPrint(libResult)

#Moving the new library to the jwplayer and videojs folder
if (os.path.exists(os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))):
    shutil.rmtree("../streamroot-videojs/src/com/streamroot/mse.swc")
shutil.copytree(os.path.normpath("mse.swc"),os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))
if (os.path.exists(os.path.normpath("../streamroot-jwplayer/jwplayer-master/src/flash/com/streamroot/mse.swc"))):
    shutil.rmtree(os.path.normpath("../streamroot-jwplayer/jwplayer-master/src/flash/com/streamroot/mse.swc"))
shutil.copytree(os.path.normpath("mse.swc"),os.path.normpath("../streamroot-jwplayer/jwplayer-master/src/flash/com/streamroot/mse.swc"))

#Moving to the jwplayer folder and compiling jwplayer
os.chdir(os.path.normpath("../streamroot-jwplayer/jwplayer-master"))
jwpResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc"),
                          os.path.normpath("src/flash/com/longtailvideo/jwplayer/player/Player.as"),
                          "-compiler.source-path=src/flash",
                          os.path.normpath("-compiler.library-path="+flex+"/frameworks/libs"),
                          "-static-link-runtime-shared-libraries=true",
                          os.path.normpath("-library-path=src/flash/com/streamroot/mse.swc"),
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-swf-version=17",
                          "-target-player=11.4.0",
                          "-use-network=false",
                          os.path.normpath("-output=bin-release/jwplayer.flash.swf"),
                          "-compiler.optimize=true",
                          "-compiler.omit-trace-statements=true",
                          "-warnings=false",
                          "-define+=JWPLAYER::version,'6.11.20141118195350280'",
                          "-define+=CONFIG::debugging,"+debug+""], stdout=subprocess.PIPE)
popenPrint(jwpResult)
shutil.copy2(os.path.normpath("bin-release/jwplayer.flash.swf"),os.path.normpath("../../sr-client-last/player_wrapper/jwplayer-wrapper/6.8/jwplayer.srflash.swf"))

#Moving to the videojs folder and compiling videojs
os.chdir(os.path.normpath("../../streamroot-videojs"))
vjsResult = subprocess.Popen([os.path.normpath(flex +"/bin/mxmlc"),
                          os.path.normpath("src/com/videojs/VideoJS.as"),
                          "-compiler.source-path=src",
                          "-compiler.library-path="+flex+"/frameworks/libs",
                          os.path.normpath("-library-path=src/com/streamroot/mse.swc"),
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-swf-version=17",
                          "-target-player=11.4.0",
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
