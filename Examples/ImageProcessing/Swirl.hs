module Examples.ImageProcessing.Swirl where

import Prelude
import QFeldspar.QDSL
import Examples.ImageProcessing.Prelude

swirl :: Qt (Float -> Image -> Image)
swirl = [|| \ scale image  ->
  let height = $$heightImage image
      width  = $$widthImage  image
      h      = i2f height
      w      = i2f width
  in  $$mkImage height width (\ i j ->
        let ir = i2f i / h - 0.5
            jr = i2f j / w - 0.5
            r  = sqrt (ir * ir + jr * jr)
            theta  = atan2 jr ir
            theta1 = 50 * scale * r * (0.5 - r) + theta
            is = round ((0.5 + if r < 0.5
                               then r * cos theta1
                               else ir) * h)
            js = round ((0.5 + if r < 0.5
                               then r * sin theta1
                               else jr) * w)
        in  $$getPixel image is js) ||]

run :: Float -> IO ()
run scale = compileImageProcessor "swirl" [|| $$swirl scale ||]
