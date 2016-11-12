module my_strategy;

import model;
import strategy;

final class MyStrategy : Strategy
{
    void move (immutable Wizard self, immutable World world,
        immutable Game game, ref Move move)
    {
        move.Speed = game.WizardForwardSpeed;
        move.StrafeSpeed = game.WizardStrafeSpeed;
        move.Turn = game.WizardMaxTurnAngle;
        move.Action = ActionType.MagicMissile;
    }
}
