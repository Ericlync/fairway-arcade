from ursina import * 

app = Ursina()

player = Entity(model = 'sphere', color=color.orange, scale_y=2)

class Ball(Entity):

def upate():
    

app.run()    