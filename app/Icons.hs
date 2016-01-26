{-# LANGUAGE NoMonomorphismRestriction, FlexibleContexts, TypeFamilies, RankNTypes #-}
module Icons
    (
    Icon(..),
    apply0Dia,
    iconToDiagram,
    nameDiagram,
    textBox,
    enclosure,
    lambdaRegion,
    resultIcon,
    guardIcon,
    apply0NDia,
    defaultLineWidth,
    ColorStyle(..),
    colorScheme
    ) where

import Diagrams.Prelude
-- import Diagrams.Backend.SVG(B)
import Diagrams.TwoD.Text(Text)
import Data.Maybe (fromMaybe)
import Data.Typeable(Typeable)

import Types(Icon(..))

-- COLO(U)RS --
colorScheme :: (Floating a, Ord a) => ColorStyle a
colorScheme = colorOnBlackScheme

data ColorStyle a = ColorStyle {
  backgroundC :: Colour a,
  lineC :: Colour a,
  textBoxTextC :: Colour a,
  textBoxC :: Colour a,
  apply0C :: Colour a,
  apply1C :: Colour a,
  boolC :: Colour a,
  lamArgResC :: Colour a,
  regionPerimC :: Colour a
}

colorOnBlackScheme :: (Floating a, Ord a) => ColorStyle a
colorOnBlackScheme = ColorStyle {
  backgroundC = black,
  lineC = white,
  textBoxTextC = white,
  textBoxC = white,
  apply0C = red,
  apply1C = cyan,
  boolC = orange,
  lamArgResC = lime,
  regionPerimC = white
}

whiteOnBlackScheme :: (Floating a, Ord a) => ColorStyle a
whiteOnBlackScheme = ColorStyle {
  backgroundC = black,
  lineC = white,
  textBoxTextC = white,
  textBoxC = white,
  apply0C = white,
  apply1C = white,
  boolC = white,
  lamArgResC = white,
  regionPerimC = white
}

-- Use this to test that all of the colors use the colorScheme
randomColorScheme :: (Floating a, Ord a) => ColorStyle a
randomColorScheme = ColorStyle {
  backgroundC = darkorchid,
  lineC = yellow,
  textBoxTextC = blue,
  textBoxC = magenta,
  apply0C = orange,
  apply1C = green,
  boolC = lightpink,
  lamArgResC = red,
  regionPerimC = cyan
}

lineCol :: (Floating a, Ord a) => Colour a
lineCol = lineC colorScheme

-- FUNCTIONS --

iconToDiagram ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b,
      Renderable (Text n) b) =>
     Icon -> [(Name, QDiagram b V2 n Any)] -> QDiagram b V2 n Any
iconToDiagram Apply0Icon _ = apply0Dia
iconToDiagram (Apply0NIcon n) _ = apply0NDia n
iconToDiagram ResultIcon _ = resultIcon
iconToDiagram BranchIcon _ = branchIcon
iconToDiagram (TextBoxIcon s) _ = textBox s
iconToDiagram (GuardIcon n) _ = guardIcon n
iconToDiagram (LambdaRegionIcon n diagramName) nameToSubdiagramMap =
  lambdaRegion n dia
  where
    dia = fromMaybe (error "iconToDiagram: subdiagram not found") $ lookup diagramName nameToSubdiagramMap

-- | Names the diagram and puts all sub-names in the namespace of the top level name.
nameDiagram :: (Floating n, Ord n, Semigroup m, Metric v, IsName nm) => nm -> QDiagram b v n m -> QDiagram b v n m
nameDiagram name dia = name .>> (dia # named name)

-- | Make an port with an integer name. Always use <> to add a ports (not === or |||)
--- since mempty has no size and will not be placed where you want it.
makePort :: (Floating n, Ord n, Semigroup m, Metric v) => Int -> QDiagram b v n m
makePort x = mempty # named x
--makePort x = circle 0.2 # fc green # named x
--makePort x = textBox (show x) # fc green # named x


--makePortDiagrams :: [P2 Double] -> Diagram B
--makePortDiagrams ::(Monoid a, Semigroup a, HasOrigin a, b ~ N a) => [P2 b] -> GeneralDiagram a
makePortDiagrams ::
   (Floating n, Ord n, Semigroup m, Metric v) =>
     [Point v n] -> QDiagram b v n m
makePortDiagrams points =
  atPoints points (map makePort ([0,1..] :: [Int]))

-- CONSTANTS --
defaultLineWidth :: (Fractional a) => a
defaultLineWidth = 0.15

-- APPLY0 ICON --
circleRadius :: (Fractional a) => a
circleRadius = 0.5

type GeneralDiagram b = (Transformable b, RealFloat (N b), Typeable (N b), HasStyle b, TrailLike b, V b ~ V2) => b

resultCircle ::
   (RealFloat (N b), Typeable (N b), Transformable b, HasStyle b,
      TrailLike b, V b ~ V2) =>
     b
resultCircle = circle circleRadius # fc (apply0C colorScheme) # lw none

apply0Triangle ::
   (Typeable (N b), Transformable b, HasStyle b, TrailLike b,
      V b ~ V2) =>
     b
apply0Triangle = eqTriangle (2 * circleRadius) # rotateBy (-1/12) # fc (apply0C colorScheme) # lw none

apply0Line ::
   (Typeable (N b), HasStyle b, TrailLike b, V b ~ V2) => b
apply0Line = rect defaultLineWidth (2 * circleRadius) # fc lineCol # lw none

--apply0Dia :: (Juxtaposable a, Semigroup a) => GeneralDiagram a
apply0Dia ::
   (RealFloat n, Typeable n, Monoid m, Semigroup m,
      TrailLike (QDiagram b V2 n m)) =>
     QDiagram b V2 n m
apply0Dia = (resultCircle ||| apply0Line ||| apply0Triangle) <> makePortDiagrams apply0PortLocations # centerXY

apply0PortLocations :: Floating a => [P2 a]
apply0PortLocations = map p2 [
  (circleRadius + defaultLineWidth + triangleWidth, 0),
  (lineCenter,circleRadius),
  (-circleRadius,0),
  (lineCenter,-circleRadius)]
  where
    triangleWidth = circleRadius * sqrt 3
    lineCenter = circleRadius + (defaultLineWidth / 2.0)

-- apply0N Icon--
-- | apply0N port locations:
-- Port 0: Function
-- Port 1: Result
-- Ports 2,3..: Arguments
apply0NDia ::
   (RealFloat n, Typeable n, Monoid m, Semigroup m,
      TrailLike (QDiagram b V2 n m)) =>
     Int -> QDiagram b V2 n m
apply0NDia n = finalDia # centerXY where
  seperation = circleRadius * 1.5
  trianglePortsCircle = hcat [
    reflectX apply0Triangle,
    hcat $ take n $ map (\x -> makePort x <> circle (circleRadius * 0.5) # fc lineCol  <> strutX seperation) [2,3..],
    makePort 1 <> alignR (circle circleRadius # fc (apply0C colorScheme) # lwG defaultLineWidth # lc (apply0C colorScheme))
    ]
  allPorts = makePort 0 <> alignL trianglePortsCircle
  topAndBottomLineWidth = width allPorts - circleRadius
  topAndBottomLine = hrule topAndBottomLineWidth # lc (apply0C colorScheme) # lwG defaultLineWidth # alignL
  finalDia = topAndBottomLine === allPorts === topAndBottomLine

-- TEXT ICON --
textBoxFontSize :: (Num a) => a
textBoxFontSize = 1
monoLetterWidthToHeightFraction :: (Fractional a) => a
monoLetterWidthToHeightFraction = 0.6
textBoxHeightFactor :: (Fractional a) => a
textBoxHeightFactor = 1.1

textBox ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b,
      Renderable (Text n) b) =>
      String -> QDiagram b V2 n Any
textBox = coloredTextBox (textBoxTextC colorScheme) $ opaque (textBoxC colorScheme)

-- Since the normal SVG text has no size, some hackery is needed to determine
-- the size of the text's bounding box.
coloredTextBox ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b,
      Renderable (Diagrams.TwoD.Text.Text n) b) =>
     Colour Double
     -> AlphaColour Double -> String -> QDiagram b V2 n Any
coloredTextBox textColor boxColor t =
  text t # fc textColor # font "freemono" # bold # fontSize (local textBoxFontSize)
  <> rect rectangleWidth (textBoxFontSize * textBoxHeightFactor) # lcA boxColor
  where
    rectangleWidth = textBoxFontSize * monoLetterWidthToHeightFraction
      * fromIntegral (length t)
      + (textBoxFontSize * 0.2)

-- ENCLOSING REGION --
enclosure ::
   (Floating n, Ord n, Typeable n, Monoid m, Semigroup m,
      TrailLike (QDiagram b V2 n m)) =>
     QDiagram b V2 n m -> QDiagram b V2 n m
enclosure dia = dia <> boundingRect (dia # frame 0.5) # lc (regionPerimC colorScheme) # lwG defaultLineWidth

-- LAMBDA ICON --
-- Don't use === here to put the port under the text box since mempty will stay
-- at the origin of the text box.
lambdaIcon ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b,
      Renderable (Diagrams.TwoD.Text.Text n) b) =>
     Int -> QDiagram b V2 n Any
lambdaIcon x = coloredTextBox (lamArgResC colorScheme) transparent "λ" # alignB <> makePort x

-- LAMBDA REGION --

-- | lambdaRegion takes as an argument the numbers of parameters to the lambda,
-- and draws the diagram inside a region with the lambda icons on top.
lambdaRegion ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b,
      Renderable (Diagrams.TwoD.Text.Text n) b) =>
     Int -> QDiagram b V2 n Any -> QDiagram b V2 n Any
lambdaRegion n dia =
  centerXY $ lambdaIcons # centerX === (enclosure dia # centerX)
  where lambdaIcons = hsep 0.4 (take n (map lambdaIcon [0,1..]))

-- RESULT ICON --
resultIcon ::
   (Typeable (N b), HasStyle b, TrailLike b, V b ~ V2) => b
resultIcon = unitSquare # lw none # fc (lamArgResC colorScheme)

-- BRANCH ICON --
branchIcon :: GeneralDiagram a
branchIcon = circle 0.3 # fc lineCol # lc lineCol

-- GUARD ICON --
guardSize :: (Fractional a) => a
guardSize = 0.7

guardTriangle ::
   (Floating n, Ord n, Typeable n, Monoid m, Semigroup m,
      TrailLike (QDiagram b V2 n m)) =>
     Int -> QDiagram b V2 n m
guardTriangle x =
  ((triangleAndPort ||| (hrule (guardSize * 0.8) # lc lineCol # lwG defaultLineWidth)) # alignR) <> makePort x # alignL
  where
    triangleAndPort = polygon (with & polyType .~ PolySides [90 @@ deg, 45 @@ deg] [guardSize, guardSize])
      # rotateBy (1/8)# lc lineCol # lwG defaultLineWidth # alignT # alignR

guardLBracket ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b) =>
     Int -> QDiagram b V2 n Any
guardLBracket x = ell # alignT # alignL <> makePort x
  where
    ellShape = fromOffsets $ map r2 [(0, guardSize), (-guardSize,0)]
    ell = ellShape # strokeLine # lc (boolC colorScheme) # lwG defaultLineWidth # lineJoin LineJoinRound

-- | The ports of the guard icon are as follows:
-- Port 0: Top result port
-- Port 1: Bottom result port
-- Ports 3,5...: The left ports for the booleans
-- Ports 2,4...: The right ports for the values
guardIcon ::
   (RealFloat n, Typeable n, Renderable (Path V2 n) b) =>
     Int -> QDiagram b V2 n Any
guardIcon n = centerXY $ makePort 1 <> alignB (vcat (take n trianglesAndBrackets # alignT) <> makePort 0)
  where
    --guardTriangles = vsep 0.4 (take n (map guardTriangle [0,1..]))
    trianglesWithPorts = map guardTriangle [2,4..]
    lBrackets = map guardLBracket [3, 5..]
    trianglesAndBrackets =
      zipWith zipper trianglesWithPorts lBrackets
    zipper thisTriangle lBrack = verticalLine === ((lBrack # extrudeRight guardSize) # alignR <> (thisTriangle # alignL))
      where
        verticalLine = vrule 0.4 # lc lineCol # lwG defaultLineWidth
