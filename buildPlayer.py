import os
import shutil
import sys
import subprocess
import time

if (os.path.exists("/opt/flex")):
    flex = "/opt/flex"
    exe = ""
elif (os.path.exists(os.path.normpath("C:/flex_sdk_4.6"))):
    flex = ("C:/flex_sdk_4.6")
    exe = ".exe"

MAIN_OUTPUT = "mse.swc"
JWP_OUTPUT = "bin-release/jwplayer.flash.swf"
VJS_OUTPUT = "dist/video-js-sr.swf"

debug = "false"
verbose = False
log_pts = "false"
swfversion = "17"
targetPlayer = "11.4.0"
color = True
vjs = True
jwp = True

startTime = time.time()

def helpParam():
    print "\npython buildPlayer.py [options]"
    print "options:"
    print "\t--debug : set debug flag to true"
    print "\t--log-pts : activate PTS log"
    print "\t--no-color : disable color"
    print "\t-v : verbose mode"
    print "\t-h : display this menu"
    print "\t--vjs : only build videojs"
    print "\t--jwp : only build jwplayer"
    print ""
    sys.exit(0)
    
def printRed(text):
    if color:
        print "\033[31m" + text + "\033[0m"
    else:
        print text
    
def printPurple(text):
    if color:
        print "\033[35m" + text + "\033[0m"
    else:
        print text
        
def printGreen(text):
    if color:
        print "\033[32m" + text + "\033[0m"
    else:
        print text

def printYellow(text):
    if color:
        print "\033[33m" + text + "\033[0m"
    else:
        print text

if (len(sys.argv)>1):
    for i in range(1, len(sys.argv)):
        if sys.argv[i] == "--debug":
            debug = "true"
            swfversion = "18"
            targetPlayer = "11.5.0"
        elif sys.argv[i] == "--log-pts":
            log_pts = "true"
        elif sys.argv[i] == "-v":
            verbose = True
        elif sys.argv[i] == "--vjs":
            jwp = False
        elif sys.argv[i] == "--jwp":
            vjs = False
        elif sys.argv[i] in ["--help","-h"]:
            helpParam()
        elif sys.argv[i] == "--no-color":
            color = False
        else:
            print "incorrect argument"
            helpParam()
if verbose:            
    print "Debug flag = " + debug
    print "LOGGING_PTS = " + log_pts 
    print "-swf-version="+swfversion
    print "-target-player="+targetPlayer

def popenPrint(result):
    result.wait()
    if verbose:
        for line in result.stdout:
            print(line)
            
    for line in result.stderr:
        while line.endswith("\n"):
            line = line[:-1]
        if not line == "":
            if color:
                line = line.replace("Error:", "\n\033[31mError\033[0m:");
                line = line.replace("Erreur:", "\n\033[31mErreur\033[0m:");
                line = line.replace("Warning:", "\n\033[33mWarning\033[0m:");
                line = line.replace("Avertissement:", "\n\033[33mAvertissement\033[0m:");
            else:
                line = line.replace("Error:", "Error:");
                line = line.replace("Erreur:", "Erreur:");
                line = line.replace("Warning:", "Warning:");
                line = line.replace("Avertissement:", "Avertissement:");
            if line.startswith('\n'):
                line = line[1:]
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
                          "-define+=CONFIG::LOGGING,false",
                          "-define+=CONFIG::LOGGING_PTS,true"],

                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)

popenPrint(workerResult)
#Remove the old library before compiling the new as mxmlc doesn't support compling into non empty folder
if (os.path.exists(MAIN_OUTPUT)):
    os.remove(MAIN_OUTPUT)
#compile the library
libResult = subprocess.Popen([os.path.normpath(flex + "/bin/compc" + exe),
                          os.path.normpath("-compiler.source-path=."),
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-include-classes=com.streamroot.StreamrootInterfaceBase",
                          "-debug="+debug+"",
                          "-define+=CONFIG::LOGGING,false",
                          "-define+=CONFIG::LOGGING_PTS," + log_pts,
                          "-directory=false",
                          "-include-sources",
                          os.path.normpath("com/streamroot/StreamrootMSE.as"),
                          "-output=" + MAIN_OUTPUT], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
popenPrint(libResult)
if not os.path.exists(MAIN_OUTPUT):
    printRed("\nBuild failed")
    sys.exit(0)
else:
    printPurple(">> " + MAIN_OUTPUT + " has been generated, sr-flash is built")

if vjs:
    if (os.path.exists(os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))):
        os.remove("../streamroot-videojs/src/com/streamroot/mse.swc")
        shutil.copyfile(os.path.normpath(MAIN_OUTPUT),os.path.normpath("../streamroot-videojs/src/com/streamroot/mse.swc"))
        printPurple(">> " + MAIN_OUTPUT + " has been copied in VideoJS directory")
        
if jwp:
    if (os.path.exists(os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))):
        os.remove(os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))
    shutil.copyfile(os.path.normpath(MAIN_OUTPUT),os.path.normpath("../streamroot-jwplayer/src/flash/com/streamroot/mse.swc"))
    printPurple(">> " + MAIN_OUTPUT + " has been copied in JWPlayer directory")

#Moving to the jwplayer folder and compiling jwplayer
if jwp:
    os.chdir(os.path.normpath("../streamroot-jwplayer"))
    if os.path.exists(JWP_OUTPUT):
        os.remove(os.path.normpath(JWP_OUTPUT))
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
                              os.path.normpath("-output="+ JWP_OUTPUT),
                              "-compiler.optimize=true",
                              "-compiler.omit-trace-statements=true",
                              "-warnings=false",
                              "-define+=JWPLAYER::version,'6.11.20141118195350280'",
                              "-define+=CONFIG::debugging,"+debug+""], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    popenPrint(jwpResult)
    if not os.path.exists(JWP_OUTPUT):
        printRed("Build failed")
        sys.exit(0)
    else:
        shutil.copy2(os.path.normpath(JWP_OUTPUT),os.path.normpath("../sr-client-last/player_wrapper/jwplayer-wrapper/dist/6.8/jwplayer.srflash.swf"))
        printPurple(">> " + "streamroot-jwplayer/" + JWP_OUTPUT + " has been generated, JWPlayer is built")
    
#Moving to the videojs folder and compiling videojs
if vjs:
    os.chdir(os.path.normpath("../streamroot-videojs"))
    if os.path.exists(VJS_OUTPUT):
        os.remove(os.path.normpath(VJS_OUTPUT))
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
                              os.path.normpath("-output=" + VJS_OUTPUT),
                              "-compiler.optimize=true",
                              "-compiler.omit-trace-statements=true",
                              "-warnings=false",
                              "-define+=CONFIG::version,\"'4.2.2'\""], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    popenPrint(vjsResult)
    if not os.path.exists(VJS_OUTPUT):
        printRed("Build failed")
        sys.exit(0)
    else:
        shutil.copy2(os.path.normpath(VJS_OUTPUT),os.path.normpath("../sr-client-last/player_wrapper/video-js-wrapper/dist/video-js-sr.swf"))
        printPurple(">> " + "streamroot-videojs/" + VJS_OUTPUT + " has been generated, VideoJS is built")

printGreen("Build successful")
time = time.time() - startTime
print "Time elapsed : " + str(time) + "s"
