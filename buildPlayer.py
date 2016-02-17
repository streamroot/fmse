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
elif (os.path.exists(os.path.expanduser("~/SDKs/Flex/4.14"))):
    flex = os.path.expanduser("~/SDKs/Flex/4.14")
    exe = ""

VJS_OUTPUT = "demo/polyfillMSE.swf"

debug = "false"
verbose = False
log_pts = "false"
swfversion = "17"
targetPlayer = "11.4.0"
color = True

startTime = time.time()

def helpParam():
    print "\npython buildPlayer.py [options]"
    print "options:"
    print "\t--debug : set debug flag to true"
    print "\t--log-pts : activate PTS log"
    print "\t--no-color : disable color"
    print "\t-v : verbose mode"
    print "\t-h : display this menu"
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

#Compile worker
workerResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc" + exe),
                          "-compiler.source-path=.",
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          os.path.normpath("com/streamroot/TranscodeWorker.as"),
                          os.path.normpath("-output=com/streamroot/TranscodeWorker.swf"),
                          "-define+=CONFIG::LOGGING,"+debug,
                          "-define+=CONFIG::LOGGING_PTS,true"],

                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)

popenPrint(workerResult)
    sys.exit(0)
else:

#compiling videojs
if os.path.exists(VJS_OUTPUT):
    os.remove(os.path.normpath(VJS_OUTPUT))
vjsResult = subprocess.Popen([os.path.normpath(flex +"/bin/mxmlc" + exe),
                          os.path.normpath("com/videojs/VideoJS.as"),
                          "-compiler.source-path=.",
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-use-network=false",
                          os.path.normpath("-output=" + VJS_OUTPUT),
                          "-compiler.optimize=true",
                          "-compiler.omit-trace-statements=false",
                          "-warnings=false",
popenPrint(vjsResult)
if not os.path.exists(VJS_OUTPUT):
    printRed("Build failed")
    sys.exit(0)
else:
    printPurple(">> " + VJS_OUTPUT + " has been generated, polyfillMSE is built")

printGreen("Build successful")
time = time.time() - startTime
print "Time elapsed : " + str(time) + "s"
