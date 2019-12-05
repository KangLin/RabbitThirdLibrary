if($env:BUILD_TARGERT -eq "android") {return 0}
if($env:BUILD_EXIT -eq "TRUE") {return 0}
if($env:RABBIT_NUMBER -eq 0) {return 0}
 
$JOB_QT_VERSION = "NO"
$RABBIT_JOB_NAME = "Environment: "
$number = ${env:RABBIT_NUMBER} - 1
$RABBIT_JOB_NAME = $RABBIT_JOB_NAME + "RABBIT_NUMBER=$number"
if ($env:APPVEYOR_BUILD_WORKER_IMAGE -eq "Visual Studio 2017")
{
    $RABBIT_JOB_NAME = $RABBIT_JOB_NAME + ", APPVEYOR_BUILD_WORKER_IMAGE=$env:APPVEYOR_BUILD_WORKER_IMAGE"
}

$RABBIT_JOB_NAME = $RABBIT_JOB_NAME + ", BUILD_TARGERT=${env:BUILD_TARGERT}, TOOLCHAIN_VERSION=${env:TOOLCHAIN_VERSION}"

if (${env:BUILD_ARCH})
{
    $RABBIT_JOB_NAME = $RABBIT_JOB_NAME + ", BUILD_ARCH=${env:BUILD_ARCH}"
}
else
{
    ${env:BUILD_ARCH} = "x64"
}
if (${env:RABBIT_CONFIG})
{
    $RABBIT_JOB_NAME = $RABBIT_JOB_NAME + ", RABBIT_CONFIG=${env:RABBIT_CONFIG}"
}
else
{
   ${env:RABBIT_CONFIG} = "Release"
}

if($env:RABBIT_NUMBER -gt $env:RABBIT_QT_NUMBER)
{
    $RABBIT_JOB_NAME = $RABBIT_JOB_NAME + ", QT_ROOT=${env:QT_ROOT}" 
    $JOB_QT_VERSION = ${env:QT_VERSION}
}
      
 write-host "Waiting for job `"$RABBIT_JOB_NAME`" to complete"
    
 $headers = @{
    "Authorization" = "Bearer $ApiKey"
    "Content-type" = "application/json"
 }
    
 [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)
 [bool]$success = $false  
 while(!$success -and ([datetime]::Now) -lt $stop) {
     $project = Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Headers $headers -Method GET
     $jobToWaitJson = $project.build.jobs | where {$_.name -eq $RABBIT_JOB_NAME} 
     if($jobToWaitJson.status -eq "failed") {break}
     $success = $jobToWaitJson.status -eq "success"
     $jobToWaitId = $jobToWaitJson.jobId;
     if (!$success) {Start-sleep 5}
 }
    
if (!$success) {throw "Job `"$RABBIT_JOB_NAME`" was not finished in $env:TimeOutMins minutes"}
if (!$jobToWaitId) {throw "Unable t get JobId for the job `"$RABBIT_JOB_NAME`""}
  
$url = "https://ci.appveyor.com/api/buildjobs/$jobToWaitId/artifacts/RABBIT_${env:BUILD_TARGERT}${env:TOOLCHAIN_VERSION}_${env:BUILD_ARCH}_qt${JOB_QT_VERSION}_${env:RABBIT_CONFIG}_${env:BUILD_VERSION}.zip"
echo $url
Start-FileDownload $url -FileName ${env:APPVEYOR_BUILD_FOLDER}/${env:BUILD_TARGERT}.zip
if(!$?){return -1}
