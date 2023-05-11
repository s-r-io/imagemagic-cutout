#!/bin/bash

# ImageMagick script by Tim Stoel
# June 24th, 2017
#
# This script cuts out images on a white-ish background
# and makes the background pure white, and resizes to 1500px square
FILES=~/Desktop/images/*
for f in $FILES
do
  echo "Processing $f..."

  # Get size of original
  sz=$(convert -format "%wx%h" $f info:)

  echo Floodfill background area with transparency
  convert $f -fuzz 10% -fill none -draw 'color 0,0 floodfill' ObjectOnTransparent.png

  echo Extract alpha channel
  convert ObjectOnTransparent.png -alpha extract Alpha.png

  echo Extract edges of alpha channel - experiment with thickness
  convert Alpha.png -edge 1 AlphaEdges.png

  echo Get difference from background for all pixels
  convert $f \( +clone -fill white -colorize 100% \) -compose difference -composite Diff.png

  echo Multiply edges with difference, so only edge pixels will have a chance of getting through to final mask
  convert AlphaEdges.png Diff.png -compose multiply -composite EdgexDiff.png

  echo Extend Alpha by differences at edges
  convert Alpha.png EdgexDiff.png -compose add -composite ReEdgedAlpha.png

  echo Apply new alpha to original image
  convert $f \( ReEdgedAlpha.png -colorspace gray \) -compose copyopacity -composite Remasked.png

  echo Place image on white background
  convert -size $sz xc:white Remasked.png -composite $f

  echo Cropping object but ignoring dust...
  convert $f -crop \
   `convert $f -virtual-pixel edge -blur 0x15 -fuzz 15% \
            -trim -format '%wx%h%O' info:`   +repage   $f

  echo Adding 20 pixels of padding...
  convert $f -bordercolor white -border 20x20 $f

  echo Resizing to 1500x1500...
  convert $f -resize 1500x1500\> \
          -size 1500x1500 xc:white +swap -gravity center  -composite \
          $f

  echo "Procesing of $f finished!"

done
