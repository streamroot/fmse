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

SOURCE_PATH = "./src/as3/"
TRANSCODER_MAIN_CLASS = SOURCE_PATH + "com/streamroot/transcoder/TranscodeWorker.as"
TRANSCODER_OUTPUT = SOURCE_PATH + "com/streamroot/transcoder/TranscodeWorker.swf"
POLYFILL_MAIN_CLASS = SOURCE_PATH + "com/streamroot/Main.as"
POLYFILL_OUTPUT = "build/fMSE.swf"

debug = "false"
log_debug = "false"
log_error = "false"
verbose = False
swfversion = "17"
targetPlayer = "11.4.0"
color = True

startTime = time.time()

def helpParam():
    print "\npython buildPlayer.py [options]"
    print "options:"
    print "\t--debug : set debug flag to true"
    print "\t--log-debug : enables debug messages logging to browser console"
    print "\t--log-error : enables error messages logging to browser console"
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
        elif sys.argv[i] == "--log-debug":
            log_debug = "true"
        elif sys.argv[i] == "--log-error":
            log_error = "true"
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
if os.path.exists(TRANSCODER_OUTPUT):
    os.remove(os.path.normpath(TRANSCODER_OUTPUT))
workerResult = subprocess.Popen([os.path.normpath(flex + "/bin/mxmlc" + exe),
                          os.path.normpath(TRANSCODER_MAIN_CLASS),
                          os.path.normpath("-output=" + TRANSCODER_OUTPUT),
                          "-static-link-runtime-shared-libraries=true",
                          "-compiler.source-path=" + SOURCE_PATH,
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-define+=CONFIG::LOG_DEBUG," + log_debug,
                          "-define+=CONFIG::LOG_ERROR," + log_error],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)

popenPrint(workerResult)
if not os.path.exists(TRANSCODER_OUTPUT):
    printRed("Transcoder build failed")
    sys.exit(0)
else:
    printPurple(">> " + TRANSCODER_OUTPUT + " has been generated, build successful")

#compiling polyfill
if os.path.exists(POLYFILL_OUTPUT):
    os.remove(os.path.normpath(POLYFILL_OUTPUT))
polyfillResult = subprocess.Popen([os.path.normpath(flex +"/bin/mxmlc" + exe),
                          os.path.normpath(POLYFILL_MAIN_CLASS),
                          os.path.normpath("-output=" + POLYFILL_OUTPUT),
                          "-compiler.source-path=" + SOURCE_PATH,
                          "-target-player="+targetPlayer+"",
                          "-swf-version="+swfversion+"",
                          "-debug="+debug+"",
                          "-static-link-runtime-shared-libraries=true",
                          "-use-network=false",
                          "-compiler.optimize=true",
                          "-default-background-color=0x000000",
                          "-default-frame-rate=30",
                          "-define+=CONFIG::LOG_DEBUG," + log_debug,
                          "-define+=CONFIG::LOG_ERROR," + log_error], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
popenPrint(polyfillResult)
if not os.path.exists(POLYFILL_OUTPUT):
    printRed("Polyfill build failed")
    sys.exit(0)
else:
    printPurple(">> " + POLYFILL_OUTPUT + " has been generated, build successful")

printGreen("Build successful")
time = time.time() - startTime
print "Time elapsed : " + str(time) + "s"
