package states;

import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;
import util.Paths;
import util.DiscordPresence;

class TitleSequence extends FlxState
{
    private var modLogoAnimated:FlxSprite;
    private var canSkip:Bool = false;
    private var skipped:Bool = false;

    override public function create()
    {
        FlxG.mouse.visible = false;
        DiscordPresence.menu();

        new FlxTimer().start(3, function(timer:FlxTimer) {
            modLogoAnimated = new FlxSprite(0, 0);
            modLogoAnimated.frames = Paths.sparrow("Im_only_an_artist_after_all");
            modLogoAnimated.animation.addByPrefix("idle", "TEEM", 24, false);
            modLogoAnimated.antialiasing = false;
            modLogoAnimated.visible = false;
            modLogoAnimated.screenCenter();
            add(modLogoAnimated);

            FlxG.sound.playMusic(Paths.sound("teamIntro"), 0.3, false);

            new FlxTimer().start(0.18, function(timer:FlxTimer) {

                modLogoAnimated.visible = true;
                modLogoAnimated.animation.play("idle", false);
                canSkip = true;
            });

            new FlxTimer().start(3, function(timer:FlxTimer) {
                FlxTween.tween(modLogoAnimated, {alpha: 0}, 4.5, {
                    ease:FlxEase.expoIn,
                    onComplete: die
                });
            });
        });
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (FlxG.keys.justPressed.ENTER && !skipped && canSkip) {
            skipped = true;
            FlxTween.tween(modLogoAnimated, {alpha: 0}, 1, {
                ease:FlxEase.expoIn,
                onComplete: die
            });
        }
    }

    function die(tween:FlxTween):Void {
        FlxG.switchState(new PlayState());
    }
}
