# F18

## build

[![Build status](https://ci.appveyor.com/api/projects/status/eg8qsklygduukk87?svg=true)](https://ci.appveyor.com/project/hernad/f18-knowhow)


## F18 log promjena

[F18 CHANGELOG.md](CHANGELOG.md)


## F18 klijent korištenje

### vise instanci F18

    ./F18 --dbf-prefix 1
    ./F18 --dbf-prefix 2

### run funkcije pri pokretanju klijenta

    ./F18 --run-on-start kalk_gen_uskladjenje_nc_95\(\)


## build notes, appveyor, bintray, downloads.bring.out.ba


### github push


Push 3.1.204 release

     git commit -am "BUILD_RELEASE 3.1.204"
     git tag 3.1.204
     git push origin 3-std --tags
   

#### bintray zip-ovi publikovanje na greenbox downloads.bring.out.ba

  * https://bintray.com/hernad/F18/F18-linux-x86
  * https://bintray.com/hernad/F18/F18-windows-x86

On greenbox-1 as root(https://redmine.bring.out.ba/issues/36922):

    VER=3.1.204

    cd /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/tmp
    rm *.zip F18 F18.exe
    curl -L  https://bintray.com/hernad/F18/download_file?file_path=F18_windows_x86_${VER}.zip  > win.zip
    unzip win.zip
    ls -lh F18.exe
    gzip -c F18.exe > F18_Windows_${VER}.gz
    mv F18_Windows_${VER}.gz /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/
    ls -lh /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/F18_Windows_${VER}.gz
    echo kraj windows

    cd /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/tmp
    rm *.zip F18 F18.exe
    curl -L  https://bintray.com/hernad/F18/download_file?file_path=F18_linux_x86_${VER}.zip  > linux.zip
    unzip linux.zip
    ls -lh F18
    gzip -c F18 > F18_Ubuntu_i686_${VER}.gz
    mv F18_Ubuntu_i686_${VER}.gz /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/
    ls -lh /data_0/f18-downloads_0/downloads.bring.out.ba/www/files/F18_Ubuntu_i686_${VER}.gz
    echo kraj linux



## Update

### Update kanal

* S - stabilne
* E - edge, posljednje verzije
* X - eksperimentalne - razvoj
