// Dev-box presentation helpers. Only inbox .NET Framework WinForms/GDI+ APIs.
using System;
using System.ComponentModel;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace BitWrecked.NativeGraphics.V1
{
    internal static class Drawing
    {
        internal static float Scale(Graphics graphics) { return graphics.DpiX / 96f; }

        internal static Color ParentFill(Control control)
        {
            for (Control parent = control.Parent; parent != null; parent = parent.Parent)
            {
                SurfacePanel surface = parent as SurfacePanel;
                if (surface != null) return surface.EffectiveHighContrast ? SystemColors.Window : surface.FillColor;
                if (parent.BackColor.A == 255) return parent.BackColor;
            }
            return control.BackColor.A == 255 ? control.BackColor : SystemColors.Control;
        }

        internal static GraphicsPath Rounded(RectangleF bounds, float radius)
        {
            GraphicsPath path = new GraphicsPath();
            radius = Math.Max(0f, Math.Min(radius, Math.Min(bounds.Width, bounds.Height) / 2f));
            if (radius < 0.5f) { path.AddRectangle(bounds); return path; }
            float diameter = radius * 2f;
            path.AddArc(bounds.Left, bounds.Top, diameter, diameter, 180f, 90f);
            path.AddArc(bounds.Right - diameter, bounds.Top, diameter, diameter, 270f, 90f);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0f, 90f);
            path.AddArc(bounds.Left, bounds.Bottom - diameter, diameter, diameter, 90f, 90f);
            path.CloseFigure();
            return path;
        }

        internal static void Surface(Graphics graphics, Rectangle bounds, float radius, Color fill, Color border, float width)
        {
            if (bounds.Width < 2 || bounds.Height < 2) return;
            float inset = width / 2f;
            RectangleF paint = new RectangleF(bounds.X + inset, bounds.Y + inset,
                Math.Max(1f, bounds.Width - width - 1f), Math.Max(1f, bounds.Height - width - 1f));
            SmoothingMode previous = graphics.SmoothingMode;
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using (GraphicsPath path = Rounded(paint, radius))
            {
                using (Brush brush = new SolidBrush(fill)) graphics.FillPath(brush, path);
                if (width > 0f && border.A > 0)
                    using (Pen pen = new Pen(border, width)) graphics.DrawPath(pen, path);
            }
            graphics.SmoothingMode = previous;
        }

        internal static void Glyph(Graphics graphics, RectangleF bounds, GlyphKind kind, Color color, float width)
        {
            if (bounds.Width < 1f || bounds.Height < 1f) return;
            SmoothingMode previous = graphics.SmoothingMode;
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            float side = Math.Min(bounds.Width, bounds.Height);
            float x = bounds.X + (bounds.Width - side) / 2f;
            float y = bounds.Y + (bounds.Height - side) / 2f;
            using (Pen pen = new Pen(color, Math.Max(1f, width)))
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
                if (kind == GlyphKind.Check)
                    graphics.DrawLines(pen, new PointF[] { new PointF(x + side * .18f, y + side * .5f), new PointF(x + side * .42f, y + side * .74f), new PointF(x + side * .82f, y + side * .25f) });
                else if (kind == GlyphKind.ArrowRight)
                {
                    graphics.DrawLine(pen, x + side * .16f, y + side * .5f, x + side * .82f, y + side * .5f);
                    graphics.DrawLines(pen, new PointF[] { new PointF(x + side * .55f, y + side * .23f), new PointF(x + side * .82f, y + side * .5f), new PointF(x + side * .55f, y + side * .77f) });
                }
                else if (kind == GlyphKind.ChevronDown)
                    graphics.DrawLines(pen, new PointF[] { new PointF(x + side * .2f, y + side * .35f), new PointF(x + side * .5f, y + side * .65f), new PointF(x + side * .8f, y + side * .35f) });
                else if (kind == GlyphKind.Shield)
                {
                    using (GraphicsPath path = new GraphicsPath())
                    {
                        path.AddLines(new PointF[] { new PointF(x + side * .5f, y + side * .1f), new PointF(x + side * .82f, y + side * .22f), new PointF(x + side * .77f, y + side * .58f) });
                        path.AddBezier(x + side * .77f, y + side * .58f, x + side * .7f, y + side * .76f, x + side * .58f, y + side * .83f, x + side * .5f, y + side * .9f);
                        path.AddBezier(x + side * .5f, y + side * .9f, x + side * .42f, y + side * .83f, x + side * .3f, y + side * .76f, x + side * .23f, y + side * .58f);
                        path.AddLine(x + side * .23f, y + side * .58f, x + side * .18f, y + side * .22f);
                        path.CloseFigure();
                        graphics.DrawPath(pen, path);
                    }
                }
                else if (kind == GlyphKind.Settings)
                {
                    graphics.DrawEllipse(pen, x + side * .24f, y + side * .24f, side * .52f, side * .52f);
                    graphics.DrawEllipse(pen, x + side * .42f, y + side * .42f, side * .16f, side * .16f);
                    for (int i = 0; i < 8; i++)
                    {
                        double angle = i * Math.PI / 4d;
                        graphics.DrawLine(pen,
                            x + side * (.5f + .26f * (float)Math.Cos(angle)), y + side * (.5f + .26f * (float)Math.Sin(angle)),
                            x + side * (.5f + .37f * (float)Math.Cos(angle)), y + side * (.5f + .37f * (float)Math.Sin(angle)));
                    }
                }
                else
                {
                    graphics.DrawEllipse(pen, x + side * .1f, y + side * .1f, side * .8f, side * .8f);
                    graphics.DrawLine(pen, x + side * .5f, y + side * .46f, x + side * .5f, y + side * .7f);
                    using (Brush brush = new SolidBrush(color)) graphics.FillEllipse(brush, x + side * .45f, y + side * .27f, side * .1f, side * .1f);
                }
            }
            graphics.SmoothingMode = previous;
        }
    }

    public enum GlyphKind { Info, Check, ArrowRight, ChevronDown, Shield, Settings }

    public static class GlyphRenderer
    {
        // Coordinates and stroke width are physical pixels; caller controls export scale.
        public static void DrawGlyph(Graphics graphics, RectangleF bounds, GlyphKind kind, Color color, float strokeWidth)
        {
            if (graphics == null) throw new ArgumentNullException("graphics");
            Drawing.Glyph(graphics, bounds, kind, color, strokeWidth);
        }
    }

    // Paints a decorative rounded surface while retaining ordinary native child controls.
    public class SurfacePanel : Panel
    {
        private Color fillColor = Color.White;
        private Color borderColor = Color.FromArgb(221, 222, 217);
        private float cornerRadius = 12f;
        private float borderWidth = 1f;
        private bool useSystemHighContrast = true;
        private bool previewHighContrast;

        public SurfacePanel()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.SupportsTransparentBackColor, true);
            BackColor = Color.Transparent;
            Padding = new Padding(16);
            AccessibleRole = AccessibleRole.Grouping;
            Size = new Size(300, 150);
        }
        public Color FillColor { get { return fillColor; } set { fillColor = value; Invalidate(); } }
        public Color BorderColor { get { return borderColor; } set { borderColor = value; Invalidate(); } }
        public float CornerRadius { get { return cornerRadius; } set { cornerRadius = Math.Max(0f, value); Invalidate(); } }
        public float BorderWidth { get { return borderWidth; } set { borderWidth = Math.Max(0f, value); Invalidate(); } }
        public bool UseSystemHighContrast { get { return useSystemHighContrast; } set { useSystemHighContrast = value; Invalidate(); } }
        public bool PreviewHighContrast { get { return previewHighContrast; } set { previewHighContrast = value; Invalidate(); } }
        [Browsable(false)] public bool EffectiveHighContrast { get { return previewHighContrast || (useSystemHighContrast && SystemInformation.HighContrast); } }
        protected override void OnPaintBackground(PaintEventArgs e)
        {
            base.OnPaintBackground(e);
            Drawing.Surface(e.Graphics, ClientRectangle, cornerRadius * Drawing.Scale(e.Graphics),
                EffectiveHighContrast ? SystemColors.Window : fillColor,
                EffectiveHighContrast ? SystemColors.WindowText : borderColor,
                borderWidth * Drawing.Scale(e.Graphics));
        }
        protected override void OnSystemColorsChanged(EventArgs e) { base.OnSystemColorsChanged(e); Invalidate(true); }
    }

    public class StatusBadge : Control
    {
        private readonly Font ownedFont = new Font("Segoe UI", 9f);
        private Color fillColor = Color.White;
        private Color borderColor = Color.FromArgb(221, 222, 217);
        private Color accentColor = Color.FromArgb(174, 64, 20);
        private float cornerRadius = 8f;
        private bool showAccent;
        private bool useSystemHighContrast = true;
        private bool previewHighContrast;

        public StatusBadge()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.SupportsTransparentBackColor, true);
            SetStyle(ControlStyles.UseTextForAccessibility, true);
            BackColor = Color.Transparent;
            ForeColor = Color.FromArgb(36, 38, 40);
            Font = ownedFont;
            Size = new Size(140, 28);
            TabStop = false;
            AccessibleRole = AccessibleRole.StaticText;
        }
        public Color FillColor { get { return fillColor; } set { fillColor = value; Invalidate(); } }
        public Color BorderColor { get { return borderColor; } set { borderColor = value; Invalidate(); } }
        public Color AccentColor { get { return accentColor; } set { accentColor = value; Invalidate(); } }
        public bool ShowAccent { get { return showAccent; } set { showAccent = value; UpdatePreferredSize(); } }
        public float CornerRadius { get { return cornerRadius; } set { cornerRadius = Math.Max(0f, value); Invalidate(); } }
        public bool UseSystemHighContrast { get { return useSystemHighContrast; } set { useSystemHighContrast = value; Invalidate(); } }
        public bool PreviewHighContrast { get { return previewHighContrast; } set { previewHighContrast = value; Invalidate(); } }
        [Browsable(false)] public bool EffectiveHighContrast { get { return previewHighContrast || (useSystemHighContrast && SystemInformation.HighContrast); } }
        public override Size GetPreferredSize(Size proposedSize)
        {
            Size text = TextRenderer.MeasureText(Text, Font, Size.Empty, TextFormatFlags.SingleLine | TextFormatFlags.NoPrefix);
            using (Graphics graphics = CreateGraphics())
            {
                float scale = Drawing.Scale(graphics);
                return new Size(text.Width + (int)Math.Ceiling((showAccent ? 32f : 22f) * scale), Math.Max(text.Height + (int)Math.Ceiling(10f * scale), (int)Math.Ceiling(28f * scale)));
            }
        }
        private void UpdatePreferredSize()
        {
            if (AutoSize && !IsDisposed)
            {
                Size preferred = GetPreferredSize(Size.Empty);
                if (Size != preferred) Size = preferred;
                if (Parent != null) Parent.PerformLayout(this, "PreferredSize");
            }
            Invalidate();
        }
        protected override void OnAutoSizeChanged(EventArgs e) { base.OnAutoSizeChanged(e); UpdatePreferredSize(); }
        protected override void OnTextChanged(EventArgs e) { base.OnTextChanged(e); UpdatePreferredSize(); }
        protected override void OnFontChanged(EventArgs e) { base.OnFontChanged(e); UpdatePreferredSize(); }
        protected override void OnPaint(PaintEventArgs e)
        {
            float scale = Drawing.Scale(e.Graphics);
            Color text = EffectiveHighContrast ? SystemColors.WindowText : ForeColor;
            Drawing.Surface(e.Graphics, ClientRectangle, cornerRadius * scale,
                EffectiveHighContrast ? SystemColors.Window : fillColor,
                EffectiveHighContrast ? SystemColors.WindowText : borderColor, scale);
            int inset = (int)Math.Ceiling(10f * scale);
            int textLeft = inset;
            if (showAccent)
            {
                float diameter = 5f * scale;
                SmoothingMode previous = e.Graphics.SmoothingMode;
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                using (Brush brush = new SolidBrush(EffectiveHighContrast ? text : accentColor))
                    e.Graphics.FillEllipse(brush, inset, (Height - diameter) / 2f, diameter, diameter);
                e.Graphics.SmoothingMode = previous;
                textLeft += (int)Math.Ceiling(12f * scale);
            }
            Rectangle rectangle = new Rectangle(textLeft, 0, Math.Max(0, Width - textLeft - inset), Height);
            TextRenderer.DrawText(e.Graphics, Text, Font, rectangle, Enabled ? text : SystemColors.GrayText,
                TextFormatFlags.SingleLine | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
            base.OnPaint(e);
        }
        protected override void OnSystemColorsChanged(EventArgs e) { base.OnSystemColorsChanged(e); Invalidate(); }
        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing) ownedFont.Dispose();
        }
    }

    public class GlyphControl : Control
    {
        private GlyphKind glyph = GlyphKind.Info;
        private bool useSystemHighContrast = true;
        private bool previewHighContrast;
        public GlyphControl()
        {
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw | ControlStyles.SupportsTransparentBackColor, true);
            BackColor = Color.Transparent;
            ForeColor = Color.FromArgb(174, 64, 20);
            Size = new Size(20, 20);
            TabStop = false;
            AccessibleRole = AccessibleRole.Graphic;
        }
        public GlyphKind Glyph { get { return glyph; } set { glyph = value; Invalidate(); } }
        public bool UseSystemHighContrast { get { return useSystemHighContrast; } set { useSystemHighContrast = value; Invalidate(); } }
        public bool PreviewHighContrast { get { return previewHighContrast; } set { previewHighContrast = value; Invalidate(); } }
        [Browsable(false)] public bool EffectiveHighContrast { get { return previewHighContrast || (useSystemHighContrast && SystemInformation.HighContrast); } }
        protected override void OnPaint(PaintEventArgs e)
        {
            float scale = Drawing.Scale(e.Graphics);
            Drawing.Glyph(e.Graphics, new RectangleF(1f * scale, 1f * scale, Math.Max(1f, Width - 2f * scale), Math.Max(1f, Height - 2f * scale)), glyph,
                Enabled ? (EffectiveHighContrast ? SystemColors.WindowText : ForeColor) : SystemColors.GrayText, 1.5f * scale);
            base.OnPaint(e);
        }
        protected override void OnSystemColorsChanged(EventArgs e) { base.OnSystemColorsChanged(e); Invalidate(); }
    }

    // Optional: native Button behavior/accessibility with an unfilled presentation.
    public class OutlineButton : Button
    {
        private Color fillColor = Color.White;
        private Color borderColor = Color.FromArgb(193, 195, 190);
        private Color accentColor = Color.FromArgb(174, 64, 20);
        private Color hoverColor = Color.FromArgb(244, 244, 240);
        private Color disabledFillColor = Color.FromArgb(244, 244, 241);
        private Color disabledBorderColor = Color.FromArgb(227, 227, 222);
        private Color disabledTextColor = Color.FromArgb(115, 117, 111);
        private float cornerRadius = 7f;
        private bool useSystemHighContrast = true;
        private bool previewHighContrast;
        private bool mouseInside;
        private bool mousePressed;
        private bool keyboardPressed;
        private bool defaultButton;

        public OutlineButton()
        {
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            UseVisualStyleBackColor = false;
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            BackColor = Color.White;
            ForeColor = Color.FromArgb(36, 38, 40);
            Size = new Size(150, 42);
            TextAlign = ContentAlignment.MiddleCenter;
        }
        public Color FillColor { get { return fillColor; } set { fillColor = value; Invalidate(); } }
        public Color BorderColor { get { return borderColor; } set { borderColor = value; Invalidate(); } }
        public Color AccentColor { get { return accentColor; } set { accentColor = value; Invalidate(); } }
        public Color HoverColor { get { return hoverColor; } set { hoverColor = value; Invalidate(); } }
        public Color DisabledFillColor { get { return disabledFillColor; } set { disabledFillColor = value; Invalidate(); } }
        public Color DisabledBorderColor { get { return disabledBorderColor; } set { disabledBorderColor = value; Invalidate(); } }
        public Color DisabledTextColor { get { return disabledTextColor; } set { disabledTextColor = value; Invalidate(); } }
        public float CornerRadius { get { return cornerRadius; } set { cornerRadius = Math.Max(0f, value); Invalidate(); } }
        public bool UseSystemHighContrast { get { return useSystemHighContrast; } set { useSystemHighContrast = value; Invalidate(); } }
        public bool PreviewHighContrast { get { return previewHighContrast; } set { previewHighContrast = value; Invalidate(); } }
        [Browsable(false)] public bool EffectiveHighContrast { get { return previewHighContrast || (useSystemHighContrast && SystemInformation.HighContrast); } }
        public override void NotifyDefault(bool value) { defaultButton = value; base.NotifyDefault(value); Invalidate(); }
        protected override void OnMouseEnter(EventArgs e) { mouseInside = true; base.OnMouseEnter(e); Invalidate(); }
        protected override void OnMouseLeave(EventArgs e) { mouseInside = false; base.OnMouseLeave(e); Invalidate(); }
        protected override void OnMouseDown(MouseEventArgs e) { if (e.Button == MouseButtons.Left) mousePressed = true; base.OnMouseDown(e); Invalidate(); }
        protected override void OnMouseUp(MouseEventArgs e) { mousePressed = false; base.OnMouseUp(e); Invalidate(); }
        protected override void OnMouseCaptureChanged(EventArgs e) { if (!Capture) mousePressed = false; base.OnMouseCaptureChanged(e); Invalidate(); }
        protected override void OnKeyDown(KeyEventArgs e) { if (e.KeyCode == Keys.Space) keyboardPressed = true; base.OnKeyDown(e); Invalidate(); }
        protected override void OnKeyUp(KeyEventArgs e) { keyboardPressed = false; base.OnKeyUp(e); Invalidate(); }
        protected override void OnGotFocus(EventArgs e) { base.OnGotFocus(e); Invalidate(); }
        protected override void OnLostFocus(EventArgs e) { keyboardPressed = false; base.OnLostFocus(e); Invalidate(); }
        protected override void OnEnabledChanged(EventArgs e) { if (!Enabled) { keyboardPressed = false; mousePressed = false; } base.OnEnabledChanged(e); Invalidate(); }
        protected override void OnSystemColorsChanged(EventArgs e) { base.OnSystemColorsChanged(e); Invalidate(); }
        protected override void OnPaint(PaintEventArgs e)
        {
            float scale = Drawing.Scale(e.Graphics);
            bool pressed = Enabled && (keyboardPressed || (mousePressed && mouseInside));
            bool highContrast = EffectiveHighContrast;
            Color fill = highContrast ? SystemColors.Control : fillColor;
            Color border = highContrast ? SystemColors.WindowText : borderColor;
            Color text = highContrast ? SystemColors.ControlText : ForeColor;
            if (!Enabled)
            {
                fill = highContrast ? SystemColors.Control : disabledFillColor;
                border = highContrast ? SystemColors.GrayText : disabledBorderColor;
                text = highContrast ? SystemColors.GrayText : disabledTextColor;
            }
            else if (pressed)
            {
                fill = highContrast ? SystemColors.Highlight : hoverColor;
                text = highContrast ? SystemColors.HighlightText : text;
            }
            else if (mouseInside) fill = highContrast ? SystemColors.ControlLight : hoverColor;

            e.Graphics.Clear(highContrast ? SystemColors.Control : Drawing.ParentFill(this));
            Drawing.Surface(e.Graphics, ClientRectangle, cornerRadius * scale, fill,
                defaultButton && Enabled && !highContrast ? accentColor : border, (defaultButton ? 1.5f : 1f) * scale);
            int inset = (int)Math.Ceiling(8f * scale);
            Rectangle textRectangle = Rectangle.Inflate(ClientRectangle, -inset, -2);
            if (pressed) textRectangle.Offset(1, 1);
            TextFormatFlags flags = TextFormatFlags.SingleLine | TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis;
            if (!UseMnemonic) flags |= TextFormatFlags.NoPrefix;
            else if (!ShowKeyboardCues) flags |= TextFormatFlags.HidePrefix;
            TextRenderer.DrawText(e.Graphics, Text, Font, textRectangle, text, flags);
            if (Focused && ShowFocusCues)
            {
                Rectangle focus = Rectangle.Inflate(ClientRectangle, -(int)Math.Ceiling(5f * scale), -(int)Math.Ceiling(5f * scale));
                if (focus.Width > 0 && focus.Height > 0) ControlPaint.DrawFocusRectangle(e.Graphics, focus, text, fill);
            }
        }
    }
}
