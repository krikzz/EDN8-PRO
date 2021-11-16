set path=C:\Program Files\7-Zip\
set name=EDN8-PRO
set filename=%name%-[%date%].7z
set home=\\datahub\krikzz\work\projects
mkdir %home%\%name%
7z -mhe a %filename% * -probomanus68K!robomanus68K! -x!.git
copy %filename% %home%\%name%\%filename%
del %filename%



pause