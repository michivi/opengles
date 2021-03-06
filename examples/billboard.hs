{-# LANGUAGE RecordWildCards, DeriveDataTypeable #-}
module Main where
import Control.Applicative
import Control.Monad
import Graphics.OpenGLES
import qualified Data.ByteString.Char8 as B
import qualified Graphics.UI.GLFW as GLFW
import Control.Concurrent

-- ghc examples/billboard.hs -lEGL -lGLESv2 -threaded && examples/billboard
main = do
	GLFW.init
	Just win <- GLFW.createWindow 600 480 "The Billboard" Nothing Nothing
	forkGL
		(GLFW.makeContextCurrent (Just win) >> return False)
		(GLFW.makeContextCurrent Nothing)
		(GLFW.swapBuffers win)
	forkIO $ mapM_ (putStrLn.("# "++)) =<< glLogContents
	future <- withGL $ mkBillboard >>= mkSomeObj
	let loop c = do
		withGL $ runAction $ draw <$> future
		endFrameGL
		putStrLn . show $ c
		GLFW.pollEvents
		closing <- GLFW.windowShouldClose win
		when (not closing) $ loop (c+1)
	loop 0

data Billboard = Billboard
	{ billboard :: Program Billboard
	, mvpMatrix :: Uniform Billboard Mat3
	, pos :: Attrib Billboard Vec2
	, uv :: Attrib Billboard Vec2
	} deriving Typeable

mkBillboard :: GL Billboard
mkBillboard = do
	Finished p <- glCompile NoFeedback
		[ vertexShader "bb.vs" vsSrc
		, fragmentShader "bb.fs" fsSrc ]
		$ \prog step msg bin ->
			putStrLn $ "> step " ++ show step ++ ", " ++ msg
	Billboard p <$> uniform "mvpMatrix"
		<*> attrib "pos" <*> attrib "uv"

vsSrc3 = B.pack $
	"#version 300 es\n\
	\ in mat4 ttt;in mat4 sss;\
	\ void main(){gl_Position = vec4(1) * ttt * sss;}"

fsSrc3 = B.pack $
	"#version 300 es\n\
	\precision mediump float;\
	\ out vec4 var;\
	\ void main(){var = vec4(1);}"

vsSrc = B.pack $
	"#version 100\n" ++
	"uniform mat3 mvpMatrix;\n" ++
	"attribute vec2 pos;\n" ++
	"attribute vec2 uv;\n" ++
	"uniform struct qqq { vec2 w[2]; };uniform struct aww { vec4 wew; vec3 www[3]; ivec2 oo[10]; qqq s[10];} ogg[20];uniform vec4 uuuuu[63];" ++
	"varying vec4 vColor;\n" ++
	"void main() {\n" ++
	"    gl_Position = vec4(mvpMatrix*vec3(pos, -1.0), 1.0);\n" ++
	"    vColor = vec4(uv, 0.5, 1.0)/*+uuuuu[10]+ogg[19].wew*/;\n" ++
	"}\n"

fsSrc = B.pack $
	"#version 100\n" ++
	"precision mediump float;\n" ++
	"varying vec4 vColor;\n" ++
	"void main() {\n" ++
	"    gl_FragColor = vColor;\n" ++
	"}\n"

data SomeObj = SomeObj
	{ prog :: Billboard
	, vao :: VertexArray Billboard
	, posBuf :: Buffer Vec2
	, uvBuf :: Buffer (V2 Word8)
	}

mkSomeObj :: Billboard -> GL SomeObj
mkSomeObj prog@Billboard{..} = do
	posBuf <- glLoad app2gl (posData,4::Int)
	uvBuf <- glLoad app2gl uvData
	vao <- glVA [ pos &= posBuf, uv &= uvBuf]
	return SomeObj {..}

posData = [V2 (-1) (-1), V2 1 (-1), V2 (-1) 1, V2 1 1]
uvData = [V2 0 0, V2 0 1, V2 1 0, V2 1 1]

draw :: SomeObj -> GL ()
draw SomeObj{..} = do
	let Billboard{..} = prog
	updateSomeObj posBuf uvBuf
	r <- glDraw triangleStrip billboard
		[ begin culling, cullFace hideBack]
		[ mvpMatrix $= eye3]
		vao $ takeFrom 0 4
	putStrLn . show $ r
updateSomeObj _ _ = return ()
