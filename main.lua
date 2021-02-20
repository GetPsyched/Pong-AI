push = require 'push'

Class = require 'class'

require 'Paddle'

require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200
AI_PADDLE_SPEED_EASY = 50
AI_PADDLE_SPEED_HARD = 100

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle('Pong')
    math.randomseed(os.time())

    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)
    love.graphics.setFont(smallFont)

    sounds = {
        ['paddle_hit'] = love.audio.newSource('paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    player1Score = 0
    player2Score = 0

    servingPlayer = 1
    winningPlayer = 0
    gameState = 'start'
    gameState1 = 'pvp'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)

    if ball.dx < 0 then
        AI_PADDLE_SPEED_EASY = 30
        AI_PADDLE_SPEED_HARD = 50
      else
        AI_PADDLE_SPEED_EASY = 80
      AI_PADDLE_SPEED_HARD = 130
    end

    if gameState == 'serve' then
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            if player2Score == 5 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                player1:reset(10, 30)
                player2:reset(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30)
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 5 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
                player1:reset(10, 30)
                player2:reset(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30)
            end
        end
    end

    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    if gameState == 'choose' then
      if love.keyboard.isDown(1) then
        gameState1 = 'pvp'
        gameState = 'serve'
      elseif love.keyboard.isDown(2) then
        gameState1 = 'pve'
        gameState = 'serve'
      elseif love.keyboard.isDown(3) then
        gameState1 = 'pve_hard'
        gameState = 'serve'
      elseif love.keyboard.isDown(4) then
        gameState1 = 'pve_impossible'
        gameState = 'serve'
      end
    end

    if gameState1 == 'pvp' then
      if love.keyboard.isDown('up') then
          player2.dy = -PADDLE_SPEED
      elseif love.keyboard.isDown('down') then
          player2.dy = PADDLE_SPEED
      else
          player2.dy = 0
        end
    end

    if gameState1 == 'pve' and gameState == 'play' then
      if (player2.y - ball.y + 8) > 0 then
          player2.dy = -AI_PADDLE_SPEED_EASY
      elseif (player2.y - ball.y + 8) < 0 then
          player2.dy = AI_PADDLE_SPEED_EASY
      else
          player2.dy = 0
      end
    end

    if gameState1 == 'pve_hard' and gameState == 'play' then
      if (player2.y - ball.y + 8) > 0 then
          player2.dy = -AI_PADDLE_SPEED_HARD
      elseif (player2.y - ball.y + 8) < 0 then
          player2.dy = AI_PADDLE_SPEED_HARD
      else
          player2.dy = 0
      end
    end

    if gameState1 == 'pve_impossible' and gameState == 'play' then
        player2.y = ball.y - 8
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'choose'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'choose'
            ball:reset()
            player1:reset(10, 30)
            player2:reset(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30)
            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

function love.draw()
    push:apply('start')

    love.graphics.clear(40, 45, 52, 255)

    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'choose' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('1. Player VS Player', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('2. Player VS AI (Easy)', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('3. Player VS AI (Hard)', 0, 30, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('4. Player VS AI (Impossible)', 0, 40, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        if winningPlayer == 2 then
          if gameState1 == 'pvp' then
            love.graphics.printf('Player 2 wins!', 0, 10, VIRTUAL_WIDTH, 'center')
          elseif gameState1 == 'pve' then
            love.graphics.printf('AI (Easy) wins!', 0, 10, VIRTUAL_WIDTH, 'center')
          elseif gameState1 == 'pve_hard' then
            love.graphics.printf('AI (Hard) wins!', 0, 10, VIRTUAL_WIDTH, 'center')
          elseif gameState1 == 'pve_impossible' then
            love.graphics.printf('AI (Impossible) wins!', 0, 10, VIRTUAL_WIDTH, 'center')
            love.graphics.printf('Obviously, lol', 0, 25, VIRTUAL_WIDTH, 'center')
          end
        else
            love.graphics.printf('Player 1 wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        end
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 50, VIRTUAL_WIDTH, 'center')
    end

    displayScore()

    player1:render()
    player2:render()
    ball:render()

    displayFPS()

    push:apply('end')
end

function displayScore()
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end

function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
