using Godot;
using System;
using System.Collections.Generic;

public partial class Transition : CanvasLayer
{
    public enum Mode { SEND, MODIFY }
    [Export] public Mode mode = Mode.SEND;

    [Export] public string NextScenePath = "";
    [Export] public bool AutoPlay = true;

    public event Action<Node2D> TransitionEnd;

    private AnimationPlayer animationPlayer;
    private ColorRect colorRect;
    private ProgressBar progressBar;

    private float _latestProgress = 0f;
    private bool _shouldEmit = true;

    private const string SHADER_PATTERNS = "res://Scenes/UI/UIorgan/Transition/transition_pattern/";
    private static Dictionary<string, Texture2D> _pngCache = new();

    public override void _EnterTree()
    {
        if (_pngCache.Count == 0)
            PreloadPngs();
    }

    private void PreloadPngs()
    {
        for (int i = 1; i <= 8; i++)
        {
            var name = i.ToString();
            var path = SHADER_PATTERNS + name + ".png";
            _pngCache[name] = GD.Load<Texture2D>(path);
        }
    }

    public void Start(string path, bool showBar = true)
    {
        NextScenePath = path;
        ResourceLoader.LoadThreadedRequest(NextScenePath, "");
        RandShaderFade();
        SetProcess(true);

        if (showBar)
        {
            progressBar.Show();
            var tween = CreateTween();
            tween.TweenProperty(progressBar, "modulate:a", 1f, .3f).From(0f);
        }
        else
        {
            progressBar.Hide();
        }
    }

    public async void RandShaderFade(int number = -1)
    {
        if (number < 0)
        {
            var rng = new RandomNumberGenerator();
            rng.Randomize();
            number = rng.RandiRange(1, 9);
        }

        if (number == 9)
            colorRect.SetInstanceShaderParameter("fade", true);
        else if (colorRect.Material is ShaderMaterial shader)
            shader.SetShaderParameter("dissolve_texture", _pngCache[number.ToString()]);

        animationPlayer.Play("ShaderFade");
        await ToSignal(animationPlayer, "animation_finished");

        var tween = CreateTween();
        tween.TweenProperty(progressBar, "modulate:a", 0f, .3f).From(1f);
        tween.TweenCallback(new Callable(progressBar, "Hide"));

        animationPlayer.PlayBackwards("ShaderFade");
        colorRect.SetInstanceShaderParameter("fade", false);
        await ToSignal(animationPlayer, "animation_finished");
    }

    public override void _Ready()
    {
        animationPlayer = GetNode<AnimationPlayer>("ColorRect/AnimationPlayer");
        colorRect = GetNode<ColorRect>("ColorRect");
        progressBar = GetNode<ProgressBar>("ProgressBar");

        if (AutoPlay && !string.IsNullOrEmpty(NextScenePath))
            Start(NextScenePath);
    }

    public override void _Process(double delta)
    {
        var progressArr = new Godot.Collections.Array();
        var status = ResourceLoader.LoadThreadedGetStatus(NextScenePath, progressArr);
        float percent = 0f;
        if (progressArr.Count > 0)
            percent = (float)((double)progressArr[0]) * 100f;

        if (percent > _latestProgress)
        {
            _latestProgress = percent;
            progressBar.Value = _latestProgress;
        }

        if (status == ResourceLoader.ThreadLoadStatus.Loaded)
        {
            var packed = (PackedScene)ResourceLoader.LoadThreadedGet(NextScenePath);
            HandleLoaded(packed);
        }
    }

    private async void HandleLoaded(PackedScene packed)
    {
        if (animationPlayer.IsPlaying())
            await ToSignal(animationPlayer, "animation_finished");

        if (mode == Mode.MODIFY && _shouldEmit)
        {
            _shouldEmit = false;
            TransitionEnd?.Invoke((Node2D)packed.Instantiate());
            SetProcess(false);
            return;
        }

        GetTree().ChangeSceneToPacked(packed);
    }
}
